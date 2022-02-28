import Peanuts.Pendulum.PendulumComponent;

class UCharacterPendulumCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	AHazePlayerCharacter Player;
	UPendulumUserComponent PendulumUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParms)
	{
		// Get player
		Player = Cast<AHazePlayerCharacter>(Owner);
		devEnsure(Player != nullptr, "You can't put this capability on a non-player. Use the StartButtonMashDefault- static functions.");

		PendulumUserComponent = UPendulumUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{ 
		if (PendulumUserComponent.CurrentPendulum == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto CurrentPendulum = PendulumUserComponent.CurrentPendulum;
		CurrentPendulum.DoPlayerPress(Player);
	}
}