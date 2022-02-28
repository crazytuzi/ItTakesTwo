
class UDialogueWidget : UHazeUserWidget
{
	UPROPERTY()
	int NumVisibleCharacters;

	UPROPERTY()
	FText DialogueText;

	UFUNCTION(BlueprintEvent)
	void OnConfirmButtonPressed()
	{

	}

	UFUNCTION(BlueprintEvent)
	void FadeOutAndDestroy()
	{

	}



}