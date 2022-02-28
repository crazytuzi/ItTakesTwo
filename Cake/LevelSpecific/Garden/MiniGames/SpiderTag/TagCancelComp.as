import Vino.Tutorial.TutorialStatics;

class UTagCancelComp : UActorComponent
{
	UObject TagStartingPointObj;

	bool bCanCancel;

	UFUNCTION()
	void ShowPlayerCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this); 
	}

	UFUNCTION()
	void RemovePlayerCancel(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}
}