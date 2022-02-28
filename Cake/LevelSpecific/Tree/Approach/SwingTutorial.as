import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
class USwingTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bHasHiddenOneJump;
	bool bHasHiddenSwingAttach;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Jump;

	UPROPERTY()
	FText SwingAttach;

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

		if (IsActioning(n"ShowSwingTutorial"))
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
		if (!IsActioning(n"ShowSwingTutorial"))
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
		PromptOne.Action = ActionNames::MovementJump;
		PromptOne.DisplayType = ETutorialPromptDisplay::Action;
		PromptOne.Mode = ETutorialPromptMode::Default;
		PromptOne.Text = Jump;

		FTutorialPrompt PromptTwo;
		PromptTwo.Action = ActionNames::SwingAttach;
		PromptTwo.DisplayType = ETutorialPromptDisplay::Action;
		PromptTwo.Mode = ETutorialPromptMode::Default;
		PromptTwo.Text = SwingAttach;

		FTutorialPromptChain PromptChain;
		PromptChain.Prompts.Add(PromptOne);
		PromptChain.Prompts.Add(PromptTwo);

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
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()))
		{
			SetTutorialPromptChainPosition(Player, this, 1);
			bHasHiddenOneJump = true;
		}

		if (MoveComp.IsGrounded() && bHasHiddenSwingAttach ||
			MoveComp.IsGrounded() && bHasHiddenOneJump)
		{
			bHasHiddenSwingAttach = false;
			bHasHiddenOneJump = false;
			ShowTutorial();
		}
	}
}