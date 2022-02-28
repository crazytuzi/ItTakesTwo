import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;

// Capability to control timing of state updating
class UFishUpdateBehaviourStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");

	// States are updated before evaluating state capabilities
	// but after states have been replicated
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

    UFishBehaviourComponent BehaviourComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        BehaviourComp = UFishBehaviourComponent::Get(Owner);
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