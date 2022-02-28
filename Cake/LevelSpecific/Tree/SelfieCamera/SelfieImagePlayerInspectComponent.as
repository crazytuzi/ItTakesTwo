import Vino.Tutorial.TutorialStatics;

event void FOnSelfieImageCancelInspection(AHazePlayerCharacter Player);

class USelfieImagePlayerInspectComponent : UActorComponent
{
	FOnSelfieImageCancelInspection OnSelfieImageCancelInspection;

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