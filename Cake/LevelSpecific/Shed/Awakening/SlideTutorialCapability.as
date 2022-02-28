import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallRun.CharacterWallRunJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;

class USlideTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UCharacterWallSlideComponent WallSlideComponent;

	UPROPERTY()
	FText Move;

	UPROPERTY()
	FText Slide;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()) ||
			Player.IsAnyCapabilityActive(UCharacterAirJumpCapability::StaticClass()) ||
			!MoveComp.IsGrounded())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (IsActioning(n"ShowSlideTutorial"))
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
		if (!IsActioning(n"ShowSlideTutorial"))
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
		ShowSlideTutorial();
	}

	void ShowSlideTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, MoveComp);

		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = Move;
		ShowTutorialPrompt(Player, Prompt, this);


		FTutorialPrompt Prompt2;
		Prompt2.Action = ActionNames::MovementCrouch;
		Prompt2.DisplayType = ETutorialPromptDisplay::Action;
		Prompt2.Mode = ETutorialPromptMode::Default;
		Prompt2.Text = Slide;
		ShowTutorialPrompt(Player, Prompt2, MoveComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, MoveComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}

		if(Player.IsAnyCapabilityActive(UCharacterWallSlideHorizontalJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
			RemoveTutorialPromptByInstigator(Player, MoveComp);
		}

		if (MoveComp.IsGrounded())
		{
			ShowSlideTutorial();
		}
	}
}