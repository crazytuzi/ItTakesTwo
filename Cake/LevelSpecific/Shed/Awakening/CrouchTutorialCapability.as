import Vino.Movement.Components.MovementComponent;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Capabilities.Crouch.CharacterCrouchCapability;
class UCrouchTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Crouch;

	bool bHasDashed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ShowCrouchTutorial"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ShowCrouchTutorial"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowTutorial();
	}

	void ShowTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);

		FTutorialPrompt PromptOne;
		PromptOne.Action = ActionNames::MovementCrouch;
		PromptOne.DisplayType = ETutorialPromptDisplay::ActionHold;
		PromptOne.Mode = ETutorialPromptMode::Default;
		PromptOne.Text = Crouch;
		ShowTutorialPrompt(Player, PromptOne, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterCrouchCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}
		else
		{
			ShowTutorial();
		}
	}
}