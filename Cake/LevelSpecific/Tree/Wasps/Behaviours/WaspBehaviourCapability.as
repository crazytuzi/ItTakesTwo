import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;

UCLASS(Abstract)
class UWaspBehaviourCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspBehaviour");
    default CapabilityDebugCategory = n"Behaviour";
	default TickGroup = ECapabilityTickGroups::GamePlay;

    private EWaspBehaviourPriority InternalPriority = EWaspBehaviourPriority::Normal;

	EWaspState State = EWaspState::None;
    UWaspBehaviourComponent BehaviourComponent = nullptr;
    UWaspAnimationComponent AnimComp = nullptr;
    UWaspEffectsComponent EffectsComp = nullptr;
	UWaspHealthComponent HealthComp = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;
	UWaspComposableSettings Settings;
	bool bExclusive = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComponent = UWaspBehaviourComponent::Get(Owner);
		AnimComp = UWaspAnimationComponent::Get(Owner);
		EffectsComp = UWaspEffectsComponent::Get(Owner);
		HealthComp = UWaspHealthComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
		ensure((BehaviourComponent != nullptr) && (EffectsComp != nullptr) && (AnimComp != nullptr) && (HealthComp != nullptr) && (CrumbComp != nullptr) && (Settings != nullptr));
        
        // Ensure that capability is evaluated in priority order        
        SetPriority(InternalPriority);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Check if we're in matching state
		if (BehaviourComponent.State != State)
    		return EHazeNetworkActivation::DontActivate; 

		// If state has changed, we have already performed a behaviour this update
		if (BehaviourComponent.State != BehaviourComponent.StateLastUpdate)
			return EHazeNetworkActivation::DontActivate;

		// Make sure we don't start any exclusive behaviour when we're already performing one at same or higher priority
		if (bExclusive && (BehaviourComponent.CurrentActivePriority >= InternalPriority))
    		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComponent.State != State)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (bExclusive && (BehaviourComponent.CurrentActivePriority > InternalPriority))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BehaviourComponent.SetRemoteState(State); 
		if (bExclusive)
			BehaviourComponent.CurrentActivePriority = InternalPriority;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bExclusive && (BehaviourComponent.CurrentActivePriority == InternalPriority))
			BehaviourComponent.CurrentActivePriority = EWaspBehaviourPriority::None;
	}

    void SetPriority(EWaspBehaviourPriority Prio)
    {
        InternalPriority = Prio;
        
        // Behaviours should evaluate late in it's tick group and in priority order (highest first)
        SetTickGroupOrder(180 - Prio); 
    }
}
