import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

class UMusicalFollowerKeyIdleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFollowerMovement");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AMusicalFollowerKey FollowerKey;
	UHazeCrumbComponent CrumbComp;
	USteeringBehaviorComponent Steering;

	FHazeAcceleratedVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		FollowerKey = Cast<AMusicalFollowerKey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if(Steering.bEnableFollowBehavior)
			return EHazeNetworkActivation::DontActivate;

		if(Steering.Follow.FollowTarget != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!Steering.bEnableAvoidanceBehavior)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetLocation.Value = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector TargetLoc = Steering.TargetLocation;
			TargetLocation.AccelerateTo(TargetLoc, 2.45f, DeltaTime);
			Owner.SetActorLocation(TargetLocation.Value);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Owner.SetActorLocationAndRotation(ConsumedParams.Location, ConsumedParams.Rotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if(Steering.bEnableFollowBehavior)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Steering.Follow.FollowTarget != nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!Steering.bEnableAvoidanceBehavior)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.CleanupCurrentMovementTrail(true);
	}
}
