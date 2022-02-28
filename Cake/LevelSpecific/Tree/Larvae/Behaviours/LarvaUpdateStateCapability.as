import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;

class ULarvaUpdateStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");

	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	ULarvaBehaviourComponent BehaviourComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = ULarvaBehaviourComponent::Get(Owner);
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
