import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;


class UFishEffectUpdateCapability : UHazeCapability
{
	UFishEffectsComponent EffectsComp;
	UFishBehaviourComponent BehaviourComponent;
	const float DeactivateAfterDuration = 5.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComponent = UFishBehaviourComponent::Get(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComponent.State != EFishState::Idle)
    		return EHazeNetworkActivation::ActivateLocal;

		if(BehaviourComponent.StateDuration <= DeactivateAfterDuration)
			return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComponent.State != EFishState::Idle)
    		return EHazeNetworkDeactivation::DontDeactivate;

		if(BehaviourComponent.StateDuration <= DeactivateAfterDuration)
			return EHazeNetworkDeactivation::DontDeactivate;

        return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// If we disable the capability, we force the effects to the correct values
		EffectsComp.UpdateEffect(1000.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EffectsComp.UpdateEffect(DeltaTime);
	}
}