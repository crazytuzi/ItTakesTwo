import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Sprint.CharacterSprintCapability;

class USprintTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText SprintText;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.IsGrounded())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (IsActioning(n"ShowSprintTutorial"))
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
		if (!IsActioning(n"ShowSprintTutorial"))
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
		ShowSprintTutorial();
	}

	void ShowSprintTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, MoveComp);

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementSprintToggle;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_Press;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = SprintText;
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterSprintCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}

		else if (MoveComp.IsGrounded())
		{
			ShowSprintTutorial();
		}
		
		else
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}
	}
}