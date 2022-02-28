import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.PointOfInterest.PointOfInterestComponent;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleMagnetInfoComponent;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleEventManager;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.Triggers.VOBarkPlayerLookAtTrigger;

event void FOnTurtleArrivedToNest();

class ASnowTurtleBaby : AHazeActor
{
	FOnTurtleArrivedToNest OnTurtleArrivedToNest;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp; 
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionObjectType(ECollisionChannel::ECC_Pawn); 
	default CapsuleComp.SetRelativeRotation(FRotator(90,0,0));
	default CapsuleComp.SetRelativeLocation(FVector(-30,0,0));
	default CapsuleComp.CapsuleHalfHeight = 175.f;
	default CapsuleComp.CapsuleRadius = 110.f;

	float CapsuleHalfHeightDefault = 175.f;
	float CapsuleHalfHeightWhenHidden = 135.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationControl;

	UPROPERTY(DefaultComponent, Attach = RotationControl)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;

	UPROPERTY(DefaultComponent, Attach = SphereComponent)
	UMagnetGenericComponent MagnetComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)	
	USnowballFightResponseComponent SnowballFightResponseComponent;

	UPointOfInterestComponent PointOfInterestComp;

	UPROPERTY(DefaultComponent)
	USnowMagnetInfoComponent SnowMagnetInfoComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000.f;
	
	UPROPERTY()
	ASnowTurtleEventManager TurtleEventManager;

	UPROPERTY()
	TSubclassOf<UHazeCapability> SnowTurtleMagnetCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> SnowTurtleMoveToNestCapability;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent SnowBallHitTurtleReaction;

	UPROPERTY(Category = "Setup")
	AVOBarkPlayerLookAtTrigger LookAtVOTrigger;

	bool bCanTriggerSnowballhit;

	float Timer = 1.5f;

	UPROPERTY(Category = "Network")
	bool bShouldNetwork = true;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem ResetTurtleSystem;

	FVector OtherSidePosition;
	FVector OtherVelocity;
	FVector TargetNestPosition;
	FVector NestForwardVector;

	FVector StartingPosition;

	float FallRespawnHeight = 2500.f;

	FVector FallLocationHeight;

	float ResetDistance = 2000.f;

	float ResetTime;

	float MaxResetTime = 3.f;

	bool bNeedsReset;

	UPROPERTY()
	bool bCanPrintToNestInfo;

	bool bMayIsAffecting;

	bool bCodyIsAffecting;

	bool bHaveEnteredNestArea;

	bool bCanMoveToNest;

	bool bIsInNest;

	bool bPlayerIsInTheWay;

	bool bIsSettledInNest;
	
	FName Tag = n"Turtle";

	float NestMovementTime = 3.3f;

	float RotationSpeed = 150.f;

	float DistanceFromNest;

	bool bCanBeImpactedByPlayer;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SkeletalMeshComponent.SetCullDistance(10000);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OtherSidePosition = ActorLocation; 

		MoveComp.Setup(CapsuleComp);

		AddCapabilitySheet(CapabilitySheet);
		MagnetComponent.OnActivatedBy.AddUFunction(this, n"OnMagnetActivated");
		MagnetComponent.OnDeactivatedBy.AddUFunction(this, n"OnMagnetDeactivated");

		AddActorTag(Tag);

		bCanBeImpactedByPlayer = true;

		SnowballFightResponseComponent.OnSnowballHit.AddUFunction(this, n"HitBySnowBall");	

		StartingPosition = ActorLocation;

		FallLocationHeight = FVector(ActorLocation.X, ActorLocation.Y, ActorLocation.Z - FallRespawnHeight);

		TurtleEventManager.OnActivateTurtles.AddUFunction(this, n"EnableTurtles");

		if (LookAtVOTrigger != nullptr)
			LookAtVOTrigger.DisableActor(this);

		DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanTriggerSnowballhit)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
				bCanTriggerSnowballhit = false;
		}

		if (HasControl())
		{
			if (ActorLocation.Z <= FallLocationHeight.Z)
			{
				if (!bNeedsReset)
				{
					NetResetBool(true);
					ResetTime = MaxResetTime;
				}

				if (bNeedsReset)
				{
					ResetTime -= DeltaTime;

					float DistanceMay = (Game::May.ActorLocation - StartingPosition).Size();
					float DistanceCody = (Game::Cody.ActorLocation - StartingPosition).Size();

					if (DistanceMay > ResetDistance && DistanceCody > ResetDistance && ResetTime <= 0.f)
					{
						ResetTurtlePosition();
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetResetBool(bool InputBool)
	{
		bNeedsReset = InputBool;
	}

	UFUNCTION(NetFunction)
	void ResetTurtlePosition()
	{
		ActorLocation = StartingPosition;
		Niagara::SpawnSystemAtLocation(ResetTurtleSystem, ActorLocation, ActorRotation);

		MoveComp.Velocity = 0.f;
		OtherSidePosition = StartingPosition;
		OtherVelocity = 0.f;

		if (HasControl())
			System::SetTimer(this, n"TimedNetResetBoolFalse", 1.f, false);
	}

	UFUNCTION()
	void TimedNetResetBoolFalse()
	{
		NetResetBool(false);
	}

	UFUNCTION()
	void HitBySnowBall(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		if (!bCanTriggerSnowballhit)
		{
			bCanTriggerSnowballhit = true;
			SkeletalMeshComponent.SetAnimBoolParam(n"bHitBySnowball", true);
			HazeAkComp.HazePostEvent(SnowBallHitTurtleReaction, n"SnowBallHitTurtleReaction");
			Timer = 2.f;
		}
	}

	UFUNCTION()
	void OnMagnetActivated(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			bMayIsAffecting = true;
		else
			bCodyIsAffecting = true;		
	}

	UFUNCTION()
	void OnMagnetDeactivated(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			bMayIsAffecting = false;
		else
			bCodyIsAffecting = false;
	}

	UFUNCTION()
	void EnableTurtles()
	{
		EnableActor(this);
		
		if (LookAtVOTrigger != nullptr)
			LookAtVOTrigger.EnableActor(this);
	}

	UFUNCTION()
	void ActivateTurtleToNest()
	{
		if (bHaveEnteredNestArea)
			return;

		bHaveEnteredNestArea = true;
		MagnetComponent.bIsDisabled = true;
		OnTurtleArrivedToNest.Broadcast();
		bCanBeImpactedByPlayer = false;
		
		System::SetTimer(this, n"SetCanMoveToNest", NestMovementTime, false);
	}

	UFUNCTION()
	void SetCanMoveToNest()
	{		
		bCanMoveToNest = true;
	}

	UFUNCTION()
	void CapsuleColliderOnHidden(bool bIsHidden)
	{
		if (bIsHidden)
			CapsuleComp.CapsuleHalfHeight = CapsuleHalfHeightWhenHidden;
		else
			CapsuleComp.CapsuleHalfHeight = CapsuleHalfHeightDefault;
	}

	UFUNCTION()
	void DisableTurtleMagnet()
	{
		MagnetComponent.bIsDisabled = true;
	}
}