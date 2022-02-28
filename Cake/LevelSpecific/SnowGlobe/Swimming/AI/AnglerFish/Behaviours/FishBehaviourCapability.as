import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Animation.FishAnimationComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Movement.FishMovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Audio.FishAudioComponent;


UCLASS(Abstract)
class UFishBehaviourCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FishBehaviour");
    default CapabilityDebugCategory = n"Behaviour";
	default TickGroup = ECapabilityTickGroups::GamePlay;

    private EFishBehaviourPriority InternalPriority = EFishBehaviourPriority::Normal;

	EFishState State = EFishState::None;
    UFishBehaviourComponent BehaviourComponent = nullptr;
	UFishAnimationComponent AnimComp;
	UFishMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UFishAudioComponent AudioComp;
    UFishEffectsComponent EffectsComp = nullptr;
	UFishComposableSettings Settings;
	bool bExclusive = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComponent = UFishBehaviourComponent::Get(Owner);
		AnimComp = UFishAnimationComponent::Get(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
		MoveComp = UFishMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		AudioComp = UFishAudioComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);

		ensure((BehaviourComponent != nullptr) && (EffectsComp != nullptr) && (MoveComp != nullptr) && (CrumbComp != nullptr) && (Settings != nullptr));
        
        // Ensure that capability is evaluated in priority order        
        SetPriority(InternalPriority);
	}

    void SetPriority(EFishBehaviourPriority Prio)
    {
        InternalPriority = Prio;
        
        // Behaviours should evaluate late in it's tick group and in priority order (highest first)
        SetTickGroupOrder(180 - Prio); 
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
			BehaviourComponent.CurrentActivePriority = EFishBehaviourPriority::None;
	}
}
