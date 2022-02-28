import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Jump.CharacterAirJumpCapability;
import Vino.Movement.Jump.CharacterJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallRun.CharacterWallRunJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;
import Cake.LevelSpecific.Shed.Awakening.SlideOnObjectTutorialComponent;

class USlideOnObectTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UCharacterWallSlideComponent WallSlideComponent;
	USlideOnObectTutorialComponent Data;

	UPROPERTY()
	FText Text;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Data = USlideOnObectTutorialComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	bool GetIsCamGoodDir() const property
	{
		if (Data.LookatObject == nullptr)
			return false;

		FVector DirToObject = Data.LookatObject.ActorLocation - Player.CurrentlyUsedCamera.WorldLocation;
		DirToObject = DirToObject.GetSafeNormal();

		float Dot = Player.CurrentlyUsedCamera.ForwardVector.DotProduct(DirToObject);

		if (Dot > 0.9f)
		{
			return true;
		}

		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsCamGoodDir )
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
		if (!IsCamGoodDir || Data.LookatObject == nullptr)
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
		ShowJumpTowardsWallTutorial();
	}

	void ShowJumpTowardsWallTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementJump;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = Text;
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}
}