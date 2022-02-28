import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Dash.CharacterAirDashCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideVerticalJumpCapability;
import Vino.Movement.SplineSlide.Capabilities.SplineSlideJumpCapability;

class UDoubleJumpDashCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bHasHiddenDoubleJump;
	bool bHasHiddenOneJump;
	bool bHasHiddenAirDash;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Jump;

	UPROPERTY()
	FText DoubleJump;

	UPROPERTY()
	FText Dash;

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

		if (IsActioning(n"ShowAirDashTutorial"))
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
		if (!IsActioning(n"ShowAirDashTutorial"))
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
		RemoveTutorialPromptByInstigator(Player, Player);
		RemoveTutorialPromptByInstigator(Player, MoveComp);

		FTutorialPrompt PromptOne;
		PromptOne.Action = ActionNames::MovementJump;
		PromptOne.DisplayType = ETutorialPromptDisplay::Action;
		PromptOne.Mode = ETutorialPromptMode::Default;
		PromptOne.Text = Jump;
		//ShowTutorialPrompt(Player, PromptOne, this);

		FTutorialPrompt PromptTwo;
		PromptTwo.Action = ActionNames::MovementJump;
		PromptTwo.DisplayType = ETutorialPromptDisplay::Action;
		PromptTwo.Mode = ETutorialPromptMode::Default;
		PromptTwo.Text = DoubleJump;
		//ShowTutorialPrompt(Player, PromptTwo, Player);

		FTutorialPrompt PromptThree;
		PromptThree.Action = ActionNames::MovementDash;
		PromptThree.DisplayType = ETutorialPromptDisplay::Action;
		PromptThree.Mode = ETutorialPromptMode::Default;
		PromptThree.Text = Dash;
		//ShowTutorialPrompt(Player, PromptThree, MoveComp);

		FTutorialPromptChain PromptChain;
		PromptChain.Prompts.Add(PromptOne);
		PromptChain.Prompts.Add(PromptTwo);
		PromptChain.Prompts.Add(PromptThree);

		ShowTutorialPromptChain(Player, PromptChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()) ||
		Player.IsAnyCapabilityActive(USplineSlideJumpCapability::StaticClass()))
		{
			SetTutorialPromptChainPosition(Player, this, 1);
			bHasHiddenOneJump = true;
		}
		else if(Player.IsAnyCapabilityActive(UCharacterAirJumpCapability::StaticClass()))
		{
			SetTutorialPromptChainPosition(Player, this, 2);
			bHasHiddenDoubleJump = true;
		}

		if (Player.IsAnyCapabilityActive(UCharacterAirDashCapability::StaticClass()))
		{
			SetTutorialPromptChainPosition(Player, this, 3);
			bHasHiddenAirDash = true;
			RemoveTutorialPromptByInstigator(Player, this);
		}

		if (MoveComp.IsGrounded() && bHasHiddenDoubleJump ||
			MoveComp.IsGrounded() && bHasHiddenOneJump ||
			MoveComp.IsGrounded() && bHasHiddenAirDash)
		{
			bHasHiddenDoubleJump = false;
			bHasHiddenOneJump = false;
			bHasHiddenAirDash = false;
			ShowTutorial();
		}
	}
}