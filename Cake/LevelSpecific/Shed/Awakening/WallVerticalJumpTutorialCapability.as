import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallRun.CharacterWallRunJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideVerticalJumpCapability;
import Cake.LevelSpecific.Shed.Awakening.WallJumpTutorialComponent;

class UWallVerticalJumpTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UCharacterWallSlideComponent WallSlideComponent;

	UWalljumpTutorialComponent WalljumpComponent;

	UPROPERTY()
	FText Jump;

	UPROPERTY()
	FText WallJump;

	bool bHasWallJumped;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		WalljumpComponent = UWalljumpTutorialComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bHasWallJumped)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()) ||
			Player.IsAnyCapabilityActive(UCharacterAirJumpCapability::StaticClass()))
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (IsActioning(n"ShowVerticalWallJumpTutorial"))
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
		if (!IsActioning(n"ShowVerticalWallJumpTutorial"))
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
		
	}

	void ShowJumpTowardsWallTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, MoveComp);
		RemoveTutorialPromptByInstigator(Player, Player);

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementJump;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = Jump;
		ShowTutorialPrompt(Player, Prompt, this);
	}

	void ShowWallJumpTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, MoveComp);
		RemoveTutorialPromptByInstigator(Player, Player);

		FTutorialPrompt Prompt2;
		Prompt2.Action = AttributeVectorNames::MovementRaw;
		Prompt2.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
		Prompt2.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, Prompt2, Player);

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementJump;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = WallJump;
		ShowTutorialPrompt(Player, Prompt, MoveComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Player.IsAnyCapabilityActive(UCharacterWallSlideVerticalJumpCapability::StaticClass()))
		{
			bHasWallJumped = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}
		
		if(Player.IsAnyCapabilityActive(UCharacterWallSlideCapability::StaticClass()))
		{
			ShowWallJumpTutorial();
		}

		if(Player.IsAnyCapabilityActive(UCharacterWallSlideVerticalJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
			RemoveTutorialPromptByInstigator(Player, MoveComp);
			RemoveTutorialPromptByInstigator(Player, Player);
			bHasWallJumped = true;
		}
	}
}