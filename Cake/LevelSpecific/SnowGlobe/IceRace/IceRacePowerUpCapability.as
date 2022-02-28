import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;
import Vino.Tutorial.TutorialStatics;

class UIceRacePowerUpCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"IceRace";

	default CapabilityTags.Add(n"IceRace");
	default CapabilityTags.Add(n"IceRacePowerUp");

	UIceRaceComponent IceRaceComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		IceRaceComponent = UIceRaceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IceRaceComponent.bHasBoost)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IceRaceComponent.bHasBoost)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		IceRaceComponent.PlayerPowerUpEffectComponent.Activate(true);
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::Action;
		TutorialPrompt.Action = ActionNames::InteractionTrigger;
		TutorialPrompt.Text = IceRaceComponent.BoostPickupPromptText;
		ShowTutorialPrompt(Player, TutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintScaled("PoweredUp", 0.f, FLinearColor::Green, 1.5f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		IceRaceComponent.PlayerPowerUpEffectComponent.Deactivate();
	}
}