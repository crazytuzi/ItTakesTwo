import Cake.SteeringBehaviors.SteeringBehaviorComponent;

class UMusicalFollowerSwitchControlCapability : UHazeCapability
{
	USteeringBehaviorComponent Steering;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Steering.Follow.FollowTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Owner.HasControl() && !Steering.Follow.FollowTarget.HasControl())
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetControlSide(Steering.Follow.FollowTarget);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
