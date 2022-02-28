import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;
import Vino.Interactions.InteractionComponent;

enum ESnowManTextureType
{
	Red,
	Yellow,
	Blue
}

class ASnowmanBreakableActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBreakableComponent BreakableMesh1;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBreakableComponent BreakableMesh2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBreakableComponent BreakableMesh3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Pile;
	default Pile.SetHiddenInGame(true);
	default Pile.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallPosMesh1;
	
	UPROPERTY(DefaultComponent, Attach = BreakableMesh2)
	USceneComponent FallPosMesh2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallPosFloor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent SnowBallResponseComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundThroughComponent GroundPoundThroughComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY(Category = "Animation")
	UAnimSequence SlapAnimCody;
	UPROPERTY(Category = "Animation")
	UAnimSequence SlapAnimMay;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem DestroyedVFX;
	UPROPERTY(Category = "Niagara")
	UNiagaraSystem DestroyedVFXLarge;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BreakPartAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundPoundAudioEvent;

	UPROPERTY(Category = "Setup")
	ESnowManTextureType SnowManTextureType;
	UPROPERTY(Category = "Setup")
	UMaterialInstance SnowmanTextureRed;
	UPROPERTY(Category = "Setup")
	UMaterialInstance SnowmanTextureYellow;
	UPROPERTY(Category = "Setup")
	UMaterialInstance SnowmanTextureBlue;
	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect OnPlayerCollideRumble;
	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect SnowballHitRumble;

	UPROPERTY(Category = "Setup")
	bool bUseAutoAim = false;
	UPROPERTY(Category = "Setup")
	float Radius = 280.f;

	FVector Direction;

	FHazeConstrainedPhysicsValue PhysicsValueTop;
	FHazeConstrainedPhysicsValue PhysicsValueMiddle;

	float PhysicsGravity = 5200.f;
	float TargetBallTopZ;
	float TargetBallMiddleZ;
	float DissolveRate = 5.f;
	float Dot;

	bool bHaveInteracted;
	bool bShouldRotate;
	bool bBreakableBroken1;
	bool bBreakableBroken3;
	bool bBreakableBroken2;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		switch (SnowManTextureType)
		{
			case ESnowManTextureType::Red:
				BreakableMesh2.SetMaterial(1, SnowmanTextureRed);
			break;
			
			case ESnowManTextureType::Yellow:
				BreakableMesh2.SetMaterial(1, SnowmanTextureYellow);
			break;

			case ESnowManTextureType::Blue:
				BreakableMesh2.SetMaterial(1, SnowmanTextureBlue);
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		GroundPoundThroughComp.OnActorGroundPoundedThrough.AddUFunction(this, n"OnGroundPounded");
		SnowBallResponseComp.OnSnowballHit.AddUFunction(this, n"OnSnowballHit");

		TargetBallMiddleZ = BreakableMesh2.RelativeLocation.Z;
		TargetBallTopZ = BreakableMesh3.RelativeLocation.Z;

		PhysicsValueTop.SnapTo(TargetBallTopZ, true);
		PhysicsValueTop.bHasUpperBound = true;
		PhysicsValueTop.bHasLowerBound = true;
		PhysicsValueTop.UpperBound = 300.f;
		PhysicsValueTop.LowerBound = -0.25f;
		PhysicsValueTop.Friction = 6.8f;
		PhysicsValueTop.UpperBounciness = 0.52f;
		PhysicsValueTop.LowerBounciness = 0.52f;

		PhysicsValueMiddle.SnapTo(TargetBallMiddleZ, true);
		PhysicsValueMiddle.bHasUpperBound = true;
		PhysicsValueMiddle.bHasLowerBound = true;
		PhysicsValueMiddle.UpperBound = 300.f;
		PhysicsValueMiddle.LowerBound = -0.55f;
		PhysicsValueMiddle.Friction = 0.8f;
		PhysicsValueMiddle.UpperBounciness = 0.02f;
		PhysicsValueMiddle.LowerBounciness = 0.02f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PlayerInRangeCheck();

		if (bHaveInteracted)
		{
			if (bShouldRotate)
			{
				Direction = ActorLocation - TargetPlayer.ActorLocation;
				Direction = Direction.ConstrainToPlane(FVector::UpVector);
				Direction.Normalize();

				FRotator TargetRot = FRotator::MakeFromX(Direction);
				TargetPlayer.SetActorRotation(FMath::RInterpTo(TargetPlayer.ActorRotation, TargetRot, DeltaTime, 12.7f));
				Dot = Direction.DotProduct(TargetPlayer.ActorForwardVector);

				if (Dot >= 0.85f)
					InteractionActivated();
			}
			else
			{
				InteractionActivated();
			}
		}

		PhysicsValueTop.AccelerateTowards(TargetBallTopZ, PhysicsGravity);
		PhysicsValueTop.Update(DeltaTime);
		PhysicsValueMiddle.AccelerateTowards(TargetBallMiddleZ, PhysicsGravity);
		PhysicsValueMiddle.Update(DeltaTime);

		BreakableMesh2.GroundCollisionOffset = -BreakableMesh2.RelativeLocation.Z;
		BreakableMesh3.GroundCollisionOffset = -BreakableMesh3.RelativeLocation.Z;

		if (bHazeEditorOnlyDebugBool)
		{
			PrintToScreen("B2: " + PhysicsValueMiddle.Value);
			PrintToScreen("B3: " + PhysicsValueTop.Value);
		}

		BreakableMesh2.RelativeLocation = FVector(BreakableMesh2.RelativeLocation.X, BreakableMesh2.RelativeLocation.Y, PhysicsValueMiddle.Value);
		BreakableMesh3.RelativeLocation = FVector(BreakableMesh3.RelativeLocation.X, BreakableMesh3.RelativeLocation.Y, PhysicsValueTop.Value);
	}

	UFUNCTION()
	void InteractionActivated()
	{
		int R = FMath::RandRange(0, 1);
		bHaveInteracted = false;

		if (TargetPlayer == Game::May)
			TargetPlayer.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"Unblock"), SlapAnimMay);
		else
			TargetPlayer.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"Unblock"), SlapAnimCody);
		
		TargetPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		TargetPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION()
	void OnSnowballHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		UBreakableComponent HitMesh = Cast<UBreakableComponent>(Hit.Component);
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(ProjectileOwner);

		if (HitMesh == nullptr)
			return;

		if (Player != nullptr)
			Player.PlayForceFeedback(SnowballHitRumble, false, true, n"SnowmanHitSnowballRumble");

		OnActorExternalHit(HitMesh);
	}

	UFUNCTION()
	void OnActorExternalHit(UBreakableComponent HitMesh = nullptr)
	{
		Niagara::SpawnSystemAtLocation(DestroyedVFX, HitMesh.WorldLocation, HitMesh.WorldRotation);
		AkComp.HazePostEvent(BreakPartAudioEvent);

		HitMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if (HitMesh != nullptr)
		{
			if (HitMesh == BreakableMesh1)
			{
				bBreakableBroken1 = true;
				BP_BreakSnowmanPart(BreakableMesh1);
				Pile.SetHiddenInGame(false);
			}
			else if (HitMesh == BreakableMesh2)
			{
				bBreakableBroken2 = true;
				BP_BreakSnowmanPart(BreakableMesh2);
			}
			else if (HitMesh == BreakableMesh3)
			{
				bBreakableBroken3 = true;
				BP_BreakSnowmanPart(BreakableMesh3);
			}

			HitMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
		}

		ActivateFall(HitMesh);

		if (bBreakableBroken1 && bBreakableBroken2 && bBreakableBroken3)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_BreakSnowmanPart(UBreakableComponent BreakableComp) {}

	void ActivateFall(UBreakableComponent HitMesh)
	{
		if (HitMesh == BreakableMesh1)
		{
			if (bBreakableBroken2)
				TargetBallTopZ = FallPosFloor.RelativeLocation.Z;
			else
				TargetBallTopZ = FallPosMesh2.RelativeLocation.Z;
			
			TargetBallMiddleZ = FallPosFloor.RelativeLocation.Z;
		}
		else if (HitMesh == BreakableMesh2)
		{
			if (bBreakableBroken1)
				TargetBallTopZ = FallPosFloor.RelativeLocation.Z;
			else
				TargetBallTopZ = FallPosMesh1.RelativeLocation.Z;
		}
	}
	
	void BreakAll(AHazePlayerCharacter Player)
	{
		bBreakableBroken1 = true;
		bBreakableBroken2 = true;
		bBreakableBroken3 = true;

		BreakableMesh1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		BreakableMesh2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		BreakableMesh3.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		BreakableMesh1.SetHiddenInGame(false);
		BreakableMesh2.SetHiddenInGame(false);
		BreakableMesh3.SetHiddenInGame(false);

		BP_BreakSnowmanPart(BreakableMesh1);
		BP_BreakSnowmanPart(BreakableMesh2);
		BP_BreakSnowmanPart(BreakableMesh3);

		AkComp.HazePostEvent(BreakPartAudioEvent);
		Player.PlayerHazeAkComp.HazePostEvent(GroundPoundAudioEvent);	

		Pile.SetHiddenInGame(false);

		Niagara::SpawnSystemAtLocation(DestroyedVFXLarge, ActorLocation, ActorRotation);

		bHaveInteracted = false;
		
		SetActorTickEnabled(false);

		Player.PlayForceFeedback(OnPlayerCollideRumble, false, true, n"SnowmanDestroyed");
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter PlayerGroundPoundingActor)
	{
		Niagara::SpawnSystemAtLocation(DestroyedVFXLarge, ActorLocation, ActorRotation);
		PlayerGroundPoundingActor.PlayerHazeAkComp.HazePostEvent(GroundPoundAudioEvent);
		BreakAll(PlayerGroundPoundingActor); 
	}

	UFUNCTION()
	void Unblock()
	{
		TargetPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		TargetPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	void PlayerInRangeCheck()
	{
		float DistanceMay = (ActorLocation - Game::May.ActorLocation).Size();
		float DistanceCody = (ActorLocation - Game::Cody.ActorLocation).Size();

		if (DistanceMay < Radius) 
		{
			if (Game::May.MovementComponent.Velocity.Size() > 1500.f)
				BreakAll(Game::May);
		}
		
		if (DistanceCody < Radius)
		{
			if (Game::Cody.MovementComponent.Velocity.Size() > 1500.f)
				BreakAll(Game::Cody);
		}
	}
}