import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineFollowerComponent;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Sap.SapManager;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Triggers.ActorTrigger;
import Cake.LevelSpecific.Tree.Boat.TreeBoat;
import Vino.Animations.PoseTrailComponent;
import Vino.Collision.LazyOverlapComponent;
event void FOnLarvaKilled();

class UTreeWaterLarvaVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTreeWaterLarvaVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ATreeWaterLarva TreeWaterLarva = Cast<ATreeWaterLarva>(Component.GetOwner());

		DrawDashedLine(TreeWaterLarva.ActorLocation, TreeWaterLarva.SplineFollowerComponent.GetSplineTransform(true).Location, FLinearColor::Green, 20.f);
		DrawPoint(TreeWaterLarva.SplineFollowerComponent.GetSplineTransform(true).Location, FLinearColor::Red, 40.f);

		DrawDashedLine(TreeWaterLarva.DropLocation, TreeWaterLarva.WaterImpactLocation, FLinearColor::Red, 20.f);
		DrawPoint(TreeWaterLarva.WaterImpactLocation, FLinearColor::Red, 40.f);
		DrawWireSphere(TreeWaterLarva.WaterImpactLocation, TreeWaterLarva.ProximityRadius, FLinearColor::Yellow, 10.f, 24);
	}
}

class UTreeWaterLarvaVisualizerComponent : UActorComponent
{

}

enum ETreeWaterLarvaMovement
{
	Crawling,
	Swimming,
	Floating
}

class ATreeWaterLarva : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UTreeWaterLarvaVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FloatingMeshComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USapAutoAimTargetComponent SapAutoAimTargetComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UConnectedHeightSplineFollowerComponent SplineFollowerComponent;

	UPROPERTY(DefaultComponent)
	USapResponseComponent SapResponseComponent;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchHitResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	ULazyOverlapComponent LazyOverlapComponent;
	default LazyOverlapComponent.AddOwnCollision(Collision);

	UPROPERTY(DefaultComponent)
	UPoseTrailComponent PoseTrail;
	default PoseTrail.Interval = 100.f;
	default PoseTrail.BoneInterpolationSpeed = 20.f; 

	UPROPERTY()
	FOnLarvaKilled OnLarvaKilled;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	AActorTrigger ActorTrigger;	

	UPROPERTY()
	int GroupIndex = 0;

	UPROPERTY()
	ETreeWaterLarvaMovement MovementType = ETreeWaterLarvaMovement::Crawling;

	UPROPERTY()
	bool bStartDisabled = false;

	UPROPERTY()
	bool bDrawDebug;

	UPROPERTY()
	float LarvaBallRadius = 400.f;

	UPROPERTY()
	bool bUseProximityTrigger;

	UPROPERTY()
	float ProximityRadius = 20000.f;
	float ProximityRadiusSquared = 0.f;

	UPROPERTY()
	float Speed = 1000.f;

	UPROPERTY()
	FVector Gravity = FVector(0.f, 0.f, -980.f) * 5.f;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	FVector AngularVelocity;

	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float DropDistance = 1.f;

	FVector DropLocation;

	UPROPERTY()
	FVector WaterImpactLocation;

	UPROPERTY()
	float SwimmingOffset = 0.f;

	bool bCanMove = false;	
	bool bInWater = false;
	bool bIsSubmerged = false;
	bool bHasResurfaced = false;

	bool bHasExploded = false;

	// Animation
	UPROPERTY(Category = "Animation")
	UAnimSequence FloatingAnimation;

	// Audio
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_WaterSplash;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_Resurface;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AudioEvent_Explosion;

	// VFX
	UPROPERTY(Category = "VFX")
	UNiagaraSystem WaterSplashEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem WaterExplosionEffect;

	float TrailHeadOffset = 0.f;

	float LastPoseTrailUpdate = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR
		SetupLarva();
#endif

		Collision.SetSphereRadius(LarvaBallRadius);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetupLarva();

		DisableActor(this);
		HazeAkComp.SetStopWhenOwnerDestroyed(false);

		FloatingMeshComponent.DetachFromParent();
		FloatingMeshComponent.SetHiddenInGame(true);

		// Set Proximity Check Timer
		System::SetTimer(this, n"CheckProximity", 0.1f, true);

		// Bind Events
		SapResponseComponent.OnSapExploded.AddUFunction(this, n"OnSapExploded");
		MatchHitResponseComponent.OnStickyHit.AddUFunction(this, n"OnMatchHit");
		SplineFollowerComponent.OnReachedSplineEnd.AddUFunction(this, n"OnReachedSplineEnd");
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionBeginOverlap");
		
		// Setup Activation trigger
		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerTriggered");

		if (ActorTrigger != nullptr)
			ActorTrigger.OnActorEnter.AddUFunction(this, n"OnActorTriggered");

		if (PlayerTrigger == nullptr && ActorTrigger == nullptr && !bUseProximityTrigger &&!bStartDisabled)
			ActivateLarva();

		// Setup movement
		switch (MovementType)
		{
			case ETreeWaterLarvaMovement::Crawling:
			{
				break;
			}
			case ETreeWaterLarvaMovement::Swimming:
			{
				FHazePlaySlotAnimationParams AnimationParams;
				AnimationParams.Animation = FloatingAnimation;
				AnimationParams.bLoop = false;
				SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"HandleDropBlendingOut"), AnimationParams);
				break;
			}
		}
		
		// Along trail, head will always be at distance 0. All other offsets will thus depend on this
		float HeadOffsetAlongMesh = PoseTrail.GetBoneOffsetAlongMesh(n"Head", SkeletalMeshComponent);

		TArray<FName> Anterior;	
		Anterior.Add(n"Spine");	
		Anterior.Add(n"Spine1"); 
		Anterior.Add(n"Spine2");
		Anterior.Add(n"Spine3");
		Anterior.Add(n"Neck");
		Anterior.Add(n"Neck1");
		Anterior.Add(n"Head"); 
		PoseTrail.AddBoneBranch(Anterior, SkeletalMeshComponent, HeadOffsetAlongMesh);

		TArray<FName> Posterior;
		Posterior.Add(n"Tail1");
		Posterior.Add(n"Tail2");
		Posterior.Add(n"Tail3");
		Posterior.Add(n"Tail4");
		Posterior.Add(n"Tail5");
		Posterior.Add(n"Tail6");
		PoseTrail.AddBoneBranch(Posterior, SkeletalMeshComponent, HeadOffsetAlongMesh);

		TrailHeadOffset = HeadOffsetAlongMesh + SkeletalMeshComponent.RelativeLocation.X; 
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (System::IsTimerActive(this, "CheckProximity"))
			System::ClearTimer(this, "CheckProximity");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Check Proximity Trigger
	//	if (bUseProximityTrigger && IsProximityTriggered())
	//		ActivateLarva();

		// Do Movement
		if (bCanMove)
		{
			float DeltaMove = Speed * DeltaTime;
			FVector Location;
			FQuat Rotation;

			// Do Water Checks
			float SubmergedAlpha = GetSubmergedAmount();
			
			if (!bInWater && SubmergedAlpha > 0.25f)		
				WaterImpact();
		
			if (bIsSubmerged && !bHasResurfaced && SubmergedAlpha < 0.9f)
				Resurface();

			if (SplineFollowerComponent.Spline != nullptr)
			{
				SplineFollowerComponent.AddDistance(DeltaMove);
			
				if (SplineFollowerComponent.Spline == nullptr || SplineFollowerComponent.DistanceOnSpline >= SplineFollowerComponent.Spline.SplineLength * DropDistance)
					Drop();
			}
			else
			{
				if (MovementType != ETreeWaterLarvaMovement::Floating)
					Drop();
			}

			switch (MovementType)
			{
				case ETreeWaterLarvaMovement::Crawling:
				{
					float Offset = SwimmingOffset * (SplineFollowerComponent.Transform.Scale3D.Y * SplineFollowerComponent.Spline.BaseWidth);
					SplineFollowerComponent.Offset = Offset;

					Velocity = (SplineFollowerComponent.Transform.Location - ActorLocation) / DeltaTime;

					// Update Animation Rate
					SkeletalMeshComponent.GlobalAnimRateScale = Velocity.Size() * 0.0015f;

					Location = SplineFollowerComponent.Transform.Location;

					Rotation = SplineFollowerComponent.Transform.Rotation;

					// Calculate Rotation
				//	FVector Direction = Velocity.ConstrainToPlane(SplineFollowerComponent.Transform.Rotation.UpVector).GetSafeNormal();
				//	Rotation = FRotator::MakeFromZX(SplineFollowerComponent.Transform.Rotation.UpVector, Direction).Quaternion();

					// Slerp rotation
					Rotation = FQuat::Slerp(ActorQuat, Rotation, 3.f * DeltaTime);

					break;
				}
				case ETreeWaterLarvaMovement::Swimming:
				{
					float Offset = SwimmingOffset * (SplineFollowerComponent.Transform.Scale3D.Y * SplineFollowerComponent.Spline.BaseWidth);
					SplineFollowerComponent.Offset = Offset;

					Velocity = (SplineFollowerComponent.Transform.Location - ActorLocation) / DeltaTime;

					Location = SplineFollowerComponent.Transform.Location;

					// Calculate Rotation
				//	FVector Direction = Velocity.ConstrainToPlane(SplineFollowerComponent.Transform.Rotation.UpVector).GetSafeNormal();
				//	Rotation = FRotator::MakeFromZX(SplineFollowerComponent.Transform.Rotation.UpVector, Direction).Quaternion();

					FVector AngularAcceleration = (ActorRightVector * 5.f)
												- (AngularVelocity * Drag)
												- (AngularVelocity * SubmergedAlpha * 2.f);

					AngularVelocity += AngularAcceleration * DeltaTime;

					Rotation = ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);			

					// More bobbing
					if (bInWater)
						FloatingMeshComponent.SetRelativeLocationAndRotation(FVector(0.f, 0.f, FMath::Sin(Time::GetGameTimeSeconds() * 3.f) * 100.f), FRotator(Time::GetGameTimeSeconds() * 00.f, Time::GetGameTimeSeconds() * 90.f, Time::GetGameTimeSeconds() * 0.f));

					break;
				}
				case ETreeWaterLarvaMovement::Floating:
				{
					// Calculate Movement
					FVector Acceleration = Gravity
										 + (-Gravity * SubmergedAlpha * 2.f)
										 - (Velocity * Drag)
										 - (Velocity * SubmergedAlpha * 4.f);

					Velocity += Acceleration * DeltaTime;

					Location = ActorLocation + Velocity * DeltaTime;

					FVector AngularAcceleration = (ActorRightVector * 2.f)
												+ (ActorForwardVector * 1.f)
												- (AngularVelocity * Drag)
												- (AngularVelocity * SubmergedAlpha * 2.f);

					AngularVelocity += AngularAcceleration * DeltaTime;

					Rotation = ActorQuat * FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);

					// More bobbing
					if (bInWater)
						FloatingMeshComponent.SetRelativeLocationAndRotation(FVector(0.f, 0.f, FMath::Sin(Time::GetGameTimeSeconds() * 3.f) * 100.f), FRotator(Time::GetGameTimeSeconds() * 00.f, Time::GetGameTimeSeconds() * 90.f, Time::GetGameTimeSeconds() * 0.f));

					break;
				}
			}

			SetActorLocationAndRotation(Location, Rotation);

			// Update pose trail after setting loc/rot so it'll base interpolations on current frame data
			if ((MovementType == ETreeWaterLarvaMovement::Crawling) && (SplineFollowerComponent.Spline != nullptr))
			{
				FRotator TrailHeadRotation = SplineFollowerComponent.Spline.GetRotationAtDistanceAlongSpline(SplineFollowerComponent.DistanceOnSpline + TrailHeadOffset, ESplineCoordinateSpace::World); 
				PoseTrail.AddTrailPoint(DeltaMove, FQuat(TrailHeadRotation));
				PoseTrail.UpdatePose(Rotation, DeltaTime);
				LastPoseTrailUpdate = Time::GameTimeSeconds;
			}
			else if (Time::GetGameTimeSince(LastPoseTrailUpdate) < 2.f)
			{
				PoseTrail.BlendOutPose(1.f, DeltaTime);
			}

#if EDITOR
			//bHazeEditorOnlyDebugBool = true;
			if (bHazeEditorOnlyDebugBool && (MovementType == ETreeWaterLarvaMovement::Crawling))
				PoseTrail.DrawDebugAlongSpline(SplineFollowerComponent.Spline, SplineFollowerComponent.DistanceOnSpline + TrailHeadOffset, FVector(0.f,0.f,300.f), SkeletalMeshComponent);
#endif
		}

	}

	UFUNCTION()
	void OnPlayerTriggered(AHazePlayerCharacter Player)
	{
		ActivateLarva();
	}

	UFUNCTION()
	void OnActorTriggered(AHazeActor Actor)
	{
		ActivateLarva();
	}

	UFUNCTION()
	void OnReachedSplineEnd(bool bForward)
	{
		switch (MovementType)
		{
			case ETreeWaterLarvaMovement::Crawling:
			{
				Drop();
				break;
			}
			case ETreeWaterLarvaMovement::Swimming:
			{
				SplineFollowerComponent.SetSplineDistance(0.f);
				break;
			}
		}
	}

	UFUNCTION()
	void SetupLarva()
	{
		SplineFollowerComponent.SetSplineActorSpline();

		if (SplineFollowerComponent.Spline != nullptr && MovementType == ETreeWaterLarvaMovement::Crawling)
		{
			SplineFollowerComponent.SetDistanceAndOffsetAtWorldLocation(ActorLocation);
			SwimmingOffset = SplineFollowerComponent.Offset / (SplineFollowerComponent.Spline.GetTransformAtDistanceAlongSpline(SplineFollowerComponent.DistanceOnSpline, ESplineCoordinateSpace::World, true).Scale3D.Y * SplineFollowerComponent.Spline.BaseWidth);
		//	SetActorLocation(SplineFollowerComponent.Spline.GetLocationAtSplinePoint(SplineFollowerComponent.Spline.LastSplinePointIndex, ESplineCoordinateSpace::World));
		}

		if (SplineFollowerComponent.Spline != nullptr && MovementType == ETreeWaterLarvaMovement::Swimming)
		{
			SplineFollowerComponent.SetDistanceAndOffsetAtWorldLocation(ActorLocation);
			SwimmingOffset = SplineFollowerComponent.Offset / (SplineFollowerComponent.Spline.GetTransformAtDistanceAlongSpline(SplineFollowerComponent.DistanceOnSpline, ESplineCoordinateSpace::World, true).Scale3D.Y * SplineFollowerComponent.Spline.BaseWidth);
		}

		if (SplineFollowerComponent.Spline != nullptr)
			DropLocation = SplineFollowerComponent.Spline.GetTransformAtDistanceAndOffset(SplineFollowerComponent.Spline.SplineLength * DropDistance, SplineFollowerComponent.Offset, true).Location;
		else
			DropLocation = ActorLocation;

		WaterImpactLocation = UpdateWaterImpactLocation();

		ProximityRadiusSquared = FMath::Square(ProximityRadius);	
	}

	UFUNCTION()
	void ActivateLarva()
	{
		if (!IsActorDisabled(this))
			return;
			
		EnableActor(this);

		bCanMove = true;
		bUseProximityTrigger = false;
	}

	UFUNCTION()
	void DeactivateLarva()
	{
		if (IsActorDisabled())
			return;

		if (System::IsTimerActive(this, "CheckProximity"))
			System::ClearTimer(this, "CheckProximity");

		DisableActor(nullptr);
	}

	UFUNCTION()
	void Drop()
	{
		MovementType = ETreeWaterLarvaMovement::Floating;

		// Clear Spline
		SplineFollowerComponent.Spline = nullptr;

		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = FloatingAnimation;
		AnimationParams.bLoop = false;
		AnimationParams.BlendTime = 1.0f;

		FHazeAnimationDelegate BlendOutDelegate;

		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"HandleDropBlendingOut"), AnimationParams);
		SkeletalMeshComponent.GlobalAnimRateScale = 1.f;
	}

	UFUNCTION()
	void HandleDropBlendingOut()
	{
		SkeletalMeshComponent.DetachFromParent();
		SkeletalMeshComponent.SetHiddenInGame(true);

		FloatingMeshComponent.AttachToComponent(Root, NAME_None, EAttachmentRule::SnapToTarget);
		FloatingMeshComponent.SetHiddenInGame(false);
	}

	UFUNCTION()
	void WaterImpact()
	{
		Niagara::SpawnSystemAtLocation(WaterSplashEffect, ActorLocation);
		HazeAkComp.HazePostEvent(AudioEvent_WaterSplash);

		bInWater = true;
	}

	UFUNCTION()
	void Resurface()
	{	
		Niagara::SpawnSystemAtLocation(WaterSplashEffect, ActorLocation);
		HazeAkComp.HazePostEvent(AudioEvent_Resurface);

		bHasResurfaced = true;
	}

	UFUNCTION()
	void ManuallyExplode()
	{
		if(HasControl())
		{
			if(bHasExploded)
				return;

			NetExplode();	
		}	
	}

	UFUNCTION()
	void Explode()
	{
		if(IsActorDisabled())
			return;

		// Always explode regardless of control side
		NetExplode();		
	}

	UFUNCTION(NetFunction)
	void NetExplode()
	{
		if (bHasExploded)
			return;

		bHasExploded = true;
		UHazeAkComponent::HazePostEventFireForget(AudioEvent_Explosion, FTransform(ActorLocation));
		
		UNiagaraSystem LarvaExplosionEffect = (MovementType == ETreeWaterLarvaMovement::Crawling) ? ExplosionEffect : WaterExplosionEffect;
		Niagara::SpawnSystemAtLocation(LarvaExplosionEffect, ActorLocation);

//		if (MovementType != ETreeWaterLarvaMovement::Swimming)
		OnLarvaKilled.Broadcast();

		if(!IsActorDisabled())
			DisableActor(nullptr);

		ExplodeAllSapsAttachedTo(RootComponent);

		if (MovementType == ETreeWaterLarvaMovement::Swimming)
		{
			if (HasControl())
				NetRespawn();
		}
	}

	UFUNCTION(NetFunction)
	void NetRespawn()
	{
		if(!Network::IsNetworked())
		{
			//Local just respawn
			Respawn();
			return;
		}


		if(HasControl())
			return;

		// Control side has told us to respawn, do so immediately since any explode has been recived
		Respawn();

		// Let control side know that any explode will be after repawn
		NetAckRespawn();
	}

	UFUNCTION(NetFunction)
	void NetAckRespawn()
	{
		if (!HasControl())
			return;

		Respawn();
	}

	UFUNCTION()
	void Respawn()
	{
		EnableActor(nullptr);

		bHasExploded = false;
		SplineFollowerComponent.SetSplineDistance(0.f);
	}

	UFUNCTION()
	FVector UpdateWaterImpactLocation()
	{
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::Vehicle);

		TArray<AActor> ActorsToIgnore;

		FHitResult HitResult;

		FVector TraceStart = DropLocation;		
		FVector TraceEnd = TraceStart + FVector::UpVector * -20000.f;

		if (System::LineTraceSingleForObjects(TraceStart, TraceEnd, ObjectTypes, true, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true, FLinearColor::Green, FLinearColor::Green, 0.f))
			return HitResult.Location;

		return ActorLocation;
	}

	UFUNCTION()
	void CheckProximity()
	{
		if (bUseProximityTrigger && IsProximityTriggered())
		{
			System::ClearTimer(this, "CheckProximity");
			ActivateLarva();
		}
	}

	UFUNCTION()
	bool IsProximityTriggered()
	{
		for (auto Player : Game::GetPlayers())
		{
			if (WaterImpactLocation.DistSquared(Player.ActorLocation) < ProximityRadiusSquared)
				return true;
		}

		return false;
	}

	UFUNCTION()
	float GetSubmergedAmount()
	{
		float SubmergedPercent = FMath::Clamp(WaterImpactLocation.Z - ActorLocation.Z + LarvaBallRadius, 0.f, LarvaBallRadius * 2.f) / (LarvaBallRadius * 2.f);

		if (SubmergedPercent >= 1.0f)
			bIsSubmerged = true;

		return SubmergedPercent;
	}

	UFUNCTION()
	void OnSapExploded(FSapAttachTarget Where, float Mass)
	{
		Explode();
	}

	UFUNCTION()
	void OnMatchHit(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
	{
		Explode();
	}

	UFUNCTION()
	void OnCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		ATreeBoat TreeBoat = Cast<ATreeBoat>(OtherActor);
		if (TreeBoat != nullptr)
		{
			FVector ImpactImpulse = (TreeBoat.ActorLocation - ActorLocation).GetSafeNormal() * 1500.f;
			TreeBoat.ImpactTreeBoat(ActorLocation, 3.f, true, ImpactImpulse, this);
			Explode();
			return;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.KillPlayer();
			Explode();
			return;
		}
	}
}