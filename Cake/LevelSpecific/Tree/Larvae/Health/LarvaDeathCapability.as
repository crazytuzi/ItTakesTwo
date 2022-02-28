import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
class ULarvaDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Death");
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

    ULarvaBehaviourComponent BehaviourComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = ULarvaBehaviourComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!BehaviourComponent.bIsDead)
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// We never need to tick
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BehaviourComponent.bIsDead = true;
		Owner.DisableActor(Owner);
        BehaviourComponent.OnDie.Broadcast(Owner);
    }
}