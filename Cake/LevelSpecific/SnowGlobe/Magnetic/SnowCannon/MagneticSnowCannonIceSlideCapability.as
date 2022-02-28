import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.ShotBySnowCannonComponent;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.MagneticSnowProjectile;

class UMagneticSnowCannonIceSlideCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagneticSnowCannonIceSlide");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	UShotBySnowCannonComponent ShotComp;

	UPROPERTY(NotEditable)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StartSlide;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent EndSlide;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent Explo;

	UHazeAsyncTraceComponent AsyncTraceComponent;
	FHazeTraceParams TraceParams;
	TArray<AActor> IgnoredActors;

	FVector RemoteSyncTargetLocationOffset;

	const float TransformSyncInterval = 2.5f;
	float SyncTimer;

	float MagnetMeshBoundsOffset;

	bool bHitSomething = false;

	uint Incarnation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ShotComp = UShotBySnowCannonComponent::GetOrCreate(Owner);
		HazeAkComponent = UHazeAkComponent::GetOrCreate(Owner);
		AsyncTraceComponent = UHazeAsyncTraceComponent::GetOrCreate(Owner);

		HazeAkComponent.SetTrackDistanceToPlayer(true);

		AMagnetBasePad MagnetOwner = Cast<AMagnetBasePad>(Owner);
		MagnetMeshBoundsOffset = MagnetOwner.Platform.StaticMesh.GetBoundingBox().Extent.Z;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ShotComp.IceWall.Actor == nullptr)
		    return EHazeNetworkActivation::DontActivate;

		if(ShotComp.CurrentState != EMagneticBasePadState::IceSliding)
		    return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(bHitSomething)
            return EHazeNetworkDeactivation::DeactivateFromControl;

		if(ShotComp.IceWall.Actor == nullptr)
            return EHazeNetworkDeactivation::DeactivateFromControl;

		if(ShotComp.CurrentState != EMagneticBasePadState::IceSliding)
            return EHazeNetworkDeactivation::DeactivateFromControl;

		if(IsActioning(n"SlideReset"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Initialize ignored actors list
		IgnoredActors.Add(Owner);
		IgnoredActors.Add(Game::May);
		IgnoredActors.Add(Game::Cody);

		// Initialize trace params structure
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.UnmarkToTraceWithOriginOffset();
		TraceParams.SetToLineTrace();
		TraceParams.IgnoreActors(IgnoredActors);

		// Fire audio event
		HazeAkComponent.HazePostEvent(StartSlide);

		SyncTimer = 0.f;
		Incarnation++;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(bHitSomething)
			SyncParams.AddActionState(n"HitSomething");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DeactivationParams.GetActionState(n"HitSomething"))
			Owner.SetCapabilityActionState(n"ShouldDestroy", EHazeActionState::Active);

		// Clear trace stuff
		IgnoredActors.Empty();
		TraceParams = FHazeTraceParams();

		// Fire audio event!
		HazeAkComponent.HazePostEvent(EndSlide, bStopOnDisable = false);
		//HazeAkComponent.HazePostEvent(Explo, bStopOnDisable = false);

		// Cleanup
		RemoteSyncTargetLocationOffset = FVector::ZeroVector;
		SyncTimer = 0.f;
		bHitSomething = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Get ice wall hit result and check if magnet should start falling
		FHitResult HitResult;
		float DownDotGravity = (-Owner.ActorUpVector).DotProduct(-FVector::UpVector);
		if(!FindSurfaceBehind(HitResult) || DownDotGravity < 0.45f)
		{
			if(HasControl())
				ShotComp.NetSetMagnetState(EMagneticBasePadState::Falling);

			return;
		}

		// Rotate magnet
		RotateTowardsSurface(HitResult);

		// Calculate move delta
		FVector DownAngle = FindSurfaceDownAngle(HitResult.ImpactNormal);
		float SlidingScaler = DownAngle.DotProduct(-FVector::UpVector);
		FVector SlidingVelocity = DownAngle * ShotComp.SlideSpeed * SlidingScaler;
		FVector DeltaMovement = SlidingVelocity * DeltaTime;

		// Perform async tracing
		FVector NormalOffset =  HitResult.ImpactNormal * 200.f;
		TraceParams.From = Owner.ActorLocation + DeltaMovement.GetSafeNormal() * MagnetMeshBoundsOffset - DeltaMovement + NormalOffset;
		TraceParams.To = TraceParams.From + DeltaMovement - NormalOffset * 2.f;
		AsyncTraceComponent.TraceSingle(TraceParams, Owner, FName("SnowCannonIceSlide_" + Incarnation), FHazeAsyncTraceComponentCompleteDelegate(this, n"OnAsyncTraceCompleted"));

		// Slide, little one
		Owner.AddActorWorldOffset(DeltaMovement);

		// Sync transform every x seconds
		if(HasControl())
		{
			if((SyncTimer += DeltaTime) >= TransformSyncInterval)
			{
				NetSyncTransform(Owner.ActorLocation, Owner.ActorRotation);
				SyncTimer = 0.f;
			}
		}
		else
		{
			FVector MoveDelta = RemoteSyncTargetLocationOffset * FMath::Square(DeltaTime);
			Owner.AddActorWorldOffset(MoveDelta);
		}
	}

	bool FindSurfaceBehind(FHitResult& OutHitResult)
	{
		return System::LineTraceSingle(Owner.ActorLocation + Owner.ActorForwardVector * 200.0f, Owner.ActorLocation - Owner.ActorForwardVector * 100.0f, ETraceTypeQuery::Visibility, false, IgnoredActors, EDrawDebugTrace::None, OutHitResult, true);
	}

	void RotateTowardsSurface(FHitResult BackHit)
	{
		FRotator ImpactRotation = Math::MakeRotFromXZ(BackHit.ImpactNormal, FVector::UpVector);
		Owner.SetActorRotation(ImpactRotation);
	}

	FVector FindSurfaceDownAngle(FVector Normal)
	{
		FVector Binormal = FVector::UpVector.CrossProduct(Normal);
		FVector DownwardsSlope = Binormal.CrossProduct(Normal);
		return DownwardsSlope;
	}

	UFUNCTION(NetFunction)
	void NetSyncTransform(const FVector& NetLocation, const FRotator& NetRotation)
	{
		if(HasControl())
			return;

		// Set remote location sync target; no need to interpolate rotation
		RemoteSyncTargetLocationOffset = NetLocation - Owner.ActorLocation;
		Owner.SetActorRotation(NetRotation);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnAsyncTraceCompleted(UObject Instigator, FName TraceId, const TArray<FHitResult>& Obstructions)
	{
		if(!IsActive())
			return;

		if(TraceId != FName("SnowCannonIceSlide_" + Incarnation))
			return;

		for(FHitResult HitResult : Obstructions)
		{
			if(HitResult.bBlockingHit)
			{
				if(HitResult.Actor != ShotComp.IceWall.Actor)
				{	
					if((HitResult.Component != nullptr && !HitResult.Component.HasTag(n"IceMagnetSlideable")) &&
					(HitResult.Actor != nullptr && HitResult.Actor.RootComponent != nullptr && !HitResult.Actor.RootComponent.HasTag(n"IceMagnetSlideable")))
					{
						if(!HitResult.Actor.IsA(AMagneticSnowProjectile::StaticClass()))
						{
							bHitSomething = true;
							return;
						}
					}
				}
			}
		}
	}
}