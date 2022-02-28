import Vino.Movement.Components.MovementComponent;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.SplineSlide.Capabilities.SplineSlideCapability;
class USlideJumpTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FText Jump;

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
		if (IsActioning(n"ShowSlideJumpTutorial"))
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
		if (!IsActioning(n"ShowSlideJumpTutorial"))
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
		if (Player.IsAnyCapabilityActive(USplineSlideCapability::StaticClass()))
		{
			ShowTutorial();
		}
		else
		{
			RemoveTutorialPromptByInstigator(Player, this);
		}
	}
}