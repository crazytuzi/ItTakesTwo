import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

class UMusicalFollowerDistanceToTargetCapability : UHazeCapability
{
	AMusicalFollower Follower;
	USteeringBehaviorComponent Steering;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Follower = Cast<AMusicalFollower>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!Steering.bEnableFollowBehavior)
			return EHazeNetworkActivation::DontActivate;

		if(Follower.TargetLocationActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Follower.TargetLocationActor == Steering.Follow.FollowTarget)
			return EHazeNetworkActivation::DontActivate;

		const float DistanceToTargetSq = Follower.TargetLocationActor.ActorLocation.DistSquared(Owner.ActorLocation);
		const float DistanceMinimumSq = FMath::Square(Follower.DistanceMinimum);

		if(DistanceToTargetSq > DistanceMinimumSq)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Steering.Follow.FollowDistance = 1.0f;
		Follower.bMoveToTargetDestination = true;
		Follower.HandleFoundTargetDestination();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
