import Peanuts.Dialogue.DialogueWidget;

delegate void FOnDialogueFinished();
delegate void FOnDialogueNextLine(int LineIndex);

class UDialogueComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDialogueWidget> WidgetClass;

	UPROPERTY()
	bool bIsInDialogue = false;

	UPROPERTY()	
	TArray<FText> DialogueText;

	FOnDialogueFinished OnFinished;

	FOnDialogueNextLine OnNextLine;
}