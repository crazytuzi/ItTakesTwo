import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullHazard;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;

class UWindWalkDoublePullHazardMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::HazardMovement);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AWindWalkDoublePullHazard HazardOwner;

	FVector Velocity;

	FRotator RandomRotationDelta;
	const float MaxRandomRotationSpeed = 120.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HazardOwner = Cast<AWindWalkDoublePullHazard>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HazardOwner.bIsFlyingTowardsPlayer)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		Velocity = HazardOwner.MoveDirection * (HazardOwner.Speed + FMath::RandRange(-HazardOwner.SpeedRandomization, HazardOwner.SpeedRandomization));
		SyncParams.AddVector(n"HazardVelocity", Velocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Velocity = ActivationParams.GetVector(n"HazardVelocity");
		RandomRotationDelta = FRotator(FMath::RandRange(0.f, MaxRandomRotationSpeed), FMath::RandRange(0.f, MaxRandomRotationSpeed), FMath::RandRange(0.f, MaxRandomRotationSpeed));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveDelta = HazardOwner.ActorLocation + Velocity * DeltaTime;
		HazardOwner.SetActorLocation(MoveDelta);

		HazardOwner.AddActorLocalRotation(RandomRotationDelta * DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		FVector HazardToAutoDestructLocation = (HazardOwner.AutoDestructLocation - HazardOwner.ActorLocation).GetSafeNormal();
		if(HazardToAutoDestructLocation.DotProduct(Velocity.GetSafeNormal()) < 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!HazardOwner.bIsFlyingTowardsPlayer)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		// If hazard is still flying, it missed the players and needs to be destroyed
		if(HazardOwner.bIsFlyingTowardsPlayer)
			SyncParams.AddActionState(n"SelfDestruct");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Velocity = FVector::ZeroVector;

		if(DeactivationParams.GetActionState(n"SelfDestruct"))
			HazardOwner.BreakHazard(DeactivationParams.ActorParams.Location);
	}
}