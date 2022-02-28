import Vino.Movement.Components.MovementComponent;
import Vino.Tutorial.TutorialStatics;
class USwapTrackutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bHasHiddenDoubleJump;
	bool bHasHiddenOneJump;
	bool bHasHiddenAirJump;

	UHazeMovementComponent MoveComp;
	
	UPROPERTY()
	FText SwapTrackText;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ShowSwapTrackTutorial"))
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
		if (!IsActioning(n"ShowSwapTrackTutorial"))
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
		FTutorialPrompt Prompt2;
		Prompt2.Action = AttributeVectorNames::MovementRaw;

		if (IsActioning(n"ShowSwapTrackTutorialLeft"))
		{
			Prompt2.DisplayType = ETutorialPromptDisplay::LeftStick_Left;
		}

		else
		{
			Prompt2.DisplayType = ETutorialPromptDisplay::LeftStick_Right;
		}
		
		
		Prompt2.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, Prompt2, this);

		FTutorialPrompt PromptThree;
		PromptThree.Action = ActionNames::SwingAttach;
		PromptThree.DisplayType = ETutorialPromptDisplay::Action;
		PromptThree.Mode = ETutorialPromptMode::Default;
		PromptThree.Text = SwapTrackText;
		ShowTutorialPrompt(Player, PromptThree, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
