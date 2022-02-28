import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;

class UGrindDashTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	bool bHasHiddenDoubleJump;
	bool bHasHiddenOneJump;
	bool bHasHiddenAirJump;

	UHazeMovementComponent MoveComp;
	UUserGrindComponent Grindcomp;

	UPROPERTY()
	FText Jump;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Grindcomp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ShowGrindDashTutorial") && Grindcomp.HasActiveGrindSpline())
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
		if (!IsActioning(n"ShowGrindDashTutorial")  || Player.IsAnyCapabilityActive(GrindingCapabilityTags::Jump))
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
		FTutorialPrompt PromptThree;
		PromptThree.Action = ActionNames::MovementDash;
		PromptThree.DisplayType = ETutorialPromptDisplay::Action;
		PromptThree.Mode = ETutorialPromptMode::Default;
		PromptThree.Text = Jump;
		ShowTutorialPrompt(Player, PromptThree, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}
