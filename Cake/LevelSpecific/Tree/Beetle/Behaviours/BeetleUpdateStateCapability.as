import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;

class UBeetleUpdateStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");

	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	UBeetleBehaviourComponent BehaviourComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = UBeetleBehaviourComponent::Get(Owner);
		if (HasControl())
	        BehaviourComponent.InitializeStates();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		BehaviourComponent.UpdateState();
	}
}
