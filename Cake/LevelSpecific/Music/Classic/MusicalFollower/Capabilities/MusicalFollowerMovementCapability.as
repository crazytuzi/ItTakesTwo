import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

class UMusicalFollowerMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFollowerMovement");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AMusicalFollower Follower;
	UHazeCrumbComponent CrumbComp;
	USteeringBehaviorComponent Steering;

	FHazeAcceleratedVector TargetLocation;
	FVector CurrentSteeringDirection;

	float CurrentDistanceDifference = 0.0f;
	float MovementSpeedMaximum = 1000.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		Follower = Cast<AMusicalFollower>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if(!Steering.bEnableFollowBehavior)
			return EHazeNetworkActivation::DontActivate;

		if(Steering.Follow.FollowTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Follower.bMoveToTargetDestination)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentSteeringDirection = Steering.ForwardVector;
		TargetLocation.Value = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Steering.bEnableFollowBehavior)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Steering.Follow.FollowTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Follower.bMoveToTargetDestination)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat FacingRotation;
		CalculateFrameMove(FacingRotation, DeltaTime);

		Owner.SetActorRotation(FacingRotation);
	}

	void CalculateFrameMove(FQuat& NewFacingRotation, float DeltaTime)
	{
		//if(HasControl())
		{
			FVector TargetLoc = Steering.TargetLocation;
			TargetLocation.AccelerateTo(TargetLoc, Follower.DistanceLag, DeltaTime);
			Owner.SetActorLocation(TargetLocation.Value + Follower.AcceleratedOffset.Value);
			//CrumbComp.LeaveMovementCrumb();
		}
		/*else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Owner.SetActorLocationAndRotation(ConsumedParams.Location, ConsumedParams.Rotation);
		}*/

		NewFacingRotation = CurrentSteeringDirection.ToOrientationQuat();
	}
}
