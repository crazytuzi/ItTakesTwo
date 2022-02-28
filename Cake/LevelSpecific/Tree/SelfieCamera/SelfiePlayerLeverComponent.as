import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieStage;

event void FOnCancelledStageLever(AHazePlayerCharacter Player);

class USelfiePlayerLeverComponent : UActorComponent
{
	ASelfieStage Stage;

	FOnCancelledStageLever OnCancelledStageLeverEvent;

	UPROPERTY(Category = "Camera Settings")
	UHazeCameraSpringArmSettingsDataAsset CamSettings; 

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt LeftTurn;
    default LeftTurn.Action = ActionNames::PrimaryLevelAbility;
    default LeftTurn.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt RightTurn;
    default RightTurn.Action = ActionNames::SecondaryLevelAbility;
    default RightTurn.MaximumDuration = -1.f;

	UFUNCTION()
	void ShowLeftTurnPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, LeftTurn, this);
	}

	UFUNCTION()
	void ShowRightTurnPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, RightTurn, this);
	}

	UFUNCTION()
	void HideAllTutorialPrompts(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void ShowPlayerCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void HidePlayerCancel(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}
}