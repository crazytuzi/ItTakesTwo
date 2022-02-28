import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallRun.CharacterWallRunJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;
import Cake.LevelSpecific.Shed.Awakening.WallJumpTutorialComponent;
class UWallSlideTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UWalljumpTutorialComponent WalljumpComponent;

	UPROPERTY()
	FText Jump;

	UPROPERTY()
	FText WallJump;

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
		if(!IsActioning(n"ShowWallJumpTutorial"))
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsAnyCapabilityActive(UCharacterAirJumpCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ShowWallJumpTutorial"))
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
		RemoveTutorialPromptByInstigator(Player, MoveComp);
	}

	bool GetIsCamGoodDir() const property
	{
		if (WalljumpComponent.LookatObject == nullptr)
			return false;

		FVector DirToObject = WalljumpComponent.LookatObject.ActorLocation - Player.CurrentlyUsedCamera.WorldLocation;
		DirToObject = DirToObject.GetSafeNormal();

		float Dot = Player.CurrentlyUsedCamera.ForwardVector.DotProduct(DirToObject);

		if (Dot > 0.7f)
		{
			return true;
		}

		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(UCharacterJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}

		if (!IsCamGoodDir)
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}

		if(Player.IsAnyCapabilityActive(UCharacterWallSlideHorizontalJumpCapability::StaticClass()))
		{
			RemoveTutorialPromptByInstigator(Player, MoveComp);
		}

		if (IsCamGoodDir)
		{
			if(Player.IsAnyCapabilityActive(UCharacterWallSlideCapability::StaticClass()))
			{
				ShowWallJumpTutorial();
			}

			if (MoveComp.IsGrounded())
			{
				ShowJumpTowardsWallTutorial();
			}
		}
	}
}