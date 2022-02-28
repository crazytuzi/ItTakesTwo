import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspSpinningWeaponComponent;


class UWaspWeaponSpinnerCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WaspAnimation");
	default TickGroup = ECapabilityTickGroups::AfterGamePlay; // After behaviours

	UWaspBehaviourComponent BehaviourComp;
	UWaspWeaponSpinningComponent WeaponComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		WeaponComp = UWaspWeaponSpinningComponent::Get(Owner);
        ensure((BehaviourComp != nullptr) && (WeaponComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsSpinState(BehaviourComp.State))
			return EHazeNetworkActivation::DontActivate;

		if ((BehaviourComp.State == EWaspState::Telegraphing) && 
			(BehaviourComp.StateDuration < WeaponComp.TelegraphDelay))
			return EHazeNetworkActivation::DontActivate;

		if (WeaponComp.bHiddenInGame)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsSpinState(BehaviourComp.State))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WeaponComp.bHiddenInGame)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool IsSpinState(EWaspState State) const
	{
		for (EWaspState SpinState : WeaponComp.SpinStates)
		{
			if (SpinState == State)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WeaponComp.StartSpinning();
    }
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WeaponComp.StopSpinning();
	}
}