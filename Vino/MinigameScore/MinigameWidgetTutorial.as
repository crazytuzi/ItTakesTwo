import Vino.MinigameScore.MinigameStatics;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialWidget;

class UMinigameWidgetTutorial : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	private void BP_SetTutorial(TArray<FTutorialPrompt> TutorialPrompts, FText Text, AHazePlayerCharacter InPlayer) {}

	UFUNCTION(BlueprintEvent)
	private void BP_ClearTutorialPrompts() {}

	UFUNCTION(BlueprintEvent)
	private UTutorialPromptWidget BP_AddPrompt(AHazePlayerCharacter InPlayer) {return nullptr;}

	UFUNCTION(BlueprintEvent)
	void BP_ShowAnimation() {}

	UFUNCTION(BlueprintEvent)
	void BP_CancelHideAnimation() {}

	UFUNCTION(BlueprintEvent)
	void BP_ReadyUpAnimation() {}

	UFUNCTION()
	void PlayShowAnimation() {BP_ShowAnimation();}

	UFUNCTION()
	void PlayHideAnimation() {BP_CancelHideAnimation();}

	UFUNCTION()
	void PlayReadyUpAnimation() {BP_ReadyUpAnimation();}

	UFUNCTION()
	void SetTutorial(TArray<FTutorialPrompt> TutorialPrompts, FText DescriptionText, AHazePlayerCharacter InPlayer)
	{
		BP_ClearTutorialPrompts();

		for (FTutorialPrompt Prompt : TutorialPrompts)
		{
			UTutorialPromptWidget Widget = BP_AddPrompt(InPlayer);
			Widget.Prompt = Prompt;
			Widget.Show();
		}

		BP_SetTutorial(TutorialPrompts, DescriptionText, InPlayer);
	}
}