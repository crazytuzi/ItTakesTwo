import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundEnterCapabililty;

class UGroundPoundTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bHasHiddenDoubleJump;
	bool bHasHiddenGroundPound;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Jump;

	UPROPERTY()
	FText GroundPound;

	bool bPerformedGroundPound = false;

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

		if (IsActioning(n"ShowGroundPoundTutorial"))
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
		if (!IsActioning(n"ShowGroundPoundTutorial") || bPerformedGroundPound)
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
		bPerformedGroundPound = false;
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
		PromptTwo.Action = ActionNames::MovementGroundPound;
		PromptTwo.DisplayType = ETutorialPromptDisplay::Action;
		PromptTwo.Mode = ETutorialPromptMode::Default;
		PromptTwo.Text = GroundPound;

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
		if (!MoveComp.IsGrounded())
		{
			SetTutorialPromptChainPosition(Player, this, 1);
			bHasHiddenGroundPound = true;
		}

		if(Player.IsAnyCapabilityActive(UCharacterGroundPoundEnterCapability::StaticClass()))
		{
			SetTutorialPromptChainPosition(Player, this, 2);
			bHasHiddenDoubleJump = true;
			RemoveTutorialPromptByInstigator(Player, this);
			bPerformedGroundPound = true;
		}

		if (MoveComp.IsGrounded() && bHasHiddenDoubleJump ||
			MoveComp.IsGrounded() && bHasHiddenGroundPound)
		{
			bHasHiddenDoubleJump = false;
			bHasHiddenGroundPound = false;
			ShowTutorial();
		}
	}
}
