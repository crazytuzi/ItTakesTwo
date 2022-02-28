import Vino.Interactions.InteractionComponent;
import Vino.Tutorial.TutorialStatics;

event void FOnPlayerCancelledPose(AHazePlayerCharacter Player);

class USelfiePosePlayerComp : UActorComponent
{
	UPROPERTY(Category = "Poses")
	TArray<UAnimSequence> AnimPoses;

	FOnPlayerCancelledPose OnPlayerCancelledPoseEvent;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt SwitchPosePositive;
    default SwitchPosePositive.Action = ActionNames::InteractionTrigger;
    default SwitchPosePositive.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt SwitchPoseNegative;
    default SwitchPoseNegative.Action = ActionNames::MovementJump;
    default SwitchPoseNegative.MaximumDuration = -1.f;

	bool bCanCancel;

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