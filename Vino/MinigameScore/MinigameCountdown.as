
event void FOnCountdownFinished();

class UMinigameCountdown : UHazeUserWidget
{
	UPROPERTY()
	FOnCountdownFinished CountdownEvent;

	UFUNCTION(BlueprintCallable)
	void OnCountdownFinished()
	{
		CountdownEvent.Broadcast();
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetCountdownFinishedText(FText Text){}

	UFUNCTION()
	void SetCountdownFinishedText(FText Text)
	{
		BP_SetCountdownFinishedText(Text);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_StartCountdown(){}

	UFUNCTION()
	void StartCountdown()
	{
		BP_StartCountdown();
	}

	UFUNCTION()
	void StopCountdown()
	{
		BP_StopCountdown();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopCountdown() {}

	UFUNCTION(BlueprintEvent)
	void BP_CountDownShowGetReady() {}
	
	UFUNCTION(BlueprintEvent)
	void BP_CountDownShowThree() {}

	UFUNCTION(BlueprintEvent)
	void BP_CountDownShowTwo() {}

	UFUNCTION(BlueprintEvent)
	void BP_CountDownShowOne() {}

	UFUNCTION(BlueprintEvent)
	void BP_CountDownShowGO() {}
}	