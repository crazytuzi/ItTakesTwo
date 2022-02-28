import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;

UCLASS(Abstract)
class ULarvaBehaviourCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Behaviour");
    default CapabilityDebugCategory = n"Behaviour";
	default TickGroup = ECapabilityTickGroups::GamePlay;
    default TickGroupOrder = 150;

	ELarvaState State = ELarvaState::None;
	bool bExclusive = true;
	ELarvaPriority Priority = ELarvaPriority::Medium;
    ULarvaBehaviourComponent BehaviourComponent = nullptr;
    ULarvaMovementDataComponent BehaviourMoveComp = nullptr;
	ULarvaComposableSettings Settings = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComponent = ULarvaBehaviourComponent::Get(Owner);
        ensure(BehaviourComponent != nullptr);
        BehaviourMoveComp = ULarvaMovementDataComponent::Get(Owner);
        ensure(BehaviourMoveComp != nullptr);
		Settings = ULarvaComposableSettings::GetSettings(Owner);
		SetTickGroupOrder(150 - Priority);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComponent.State != State)
    		return EHazeNetworkActivation::DontActivate;
		if (bExclusive && (BehaviourComponent.CurrentActivePriority >= Priority))
    		return EHazeNetworkActivation::DontActivate; // Need higher prio to override other behaviour
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComponent.State != State)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (bExclusive && (BehaviourComponent.CurrentActivePriority > Priority))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; // Pther with higher prio has taken over
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!HasControl())
			BehaviourComponent.State = State; // Remote side match state
		if (bExclusive)
			BehaviourComponent.CurrentActivePriority = Priority;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bExclusive)
			BehaviourComponent.CurrentActivePriority = ELarvaPriority::None;
	}
}
