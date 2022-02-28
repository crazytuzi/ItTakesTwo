import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

// Capability to control timing of state updating
class UWaspUpdateBehaviourStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");

	// States are updated before evaluating state capabilities
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

    UWaspBehaviourComponent BehaviourComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		ensure(BehaviourComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		BehaviourComp.UpdateState();
	}
}