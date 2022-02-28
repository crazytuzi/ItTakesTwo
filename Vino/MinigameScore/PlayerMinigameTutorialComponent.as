import Vino.Tutorial.TutorialStatics;
import Vino.Interactions.DoubleInteractComponent;

event void FOnMinigamePlayerReady(AHazePlayerCharacter Player);
event void FOnTutorialCancel();
event void FOnTutorialCancelFromPlayer(AHazePlayerCharacter Player);

class UPlayerMinigameTutorialComponent : UActorComponent
{
	FOnMinigamePlayerReady OnMinigamePlayerReady;

	// FOnTutorialCancel OnTutorialCancel;

	FOnTutorialCancelFromPlayer OnTutorialCancelFromPlayer;

	UFUNCTION()
	void ShowTutorialCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void HideTutorialCancel(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}
}