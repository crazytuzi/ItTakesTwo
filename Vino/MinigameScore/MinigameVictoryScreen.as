import Vino.MinigameScore.MinigameStatics;

event void FOnVictoryScreenFinished();

class UMinigameVictoryScreen : UHazeUserWidget
{
	UPROPERTY()
	FOnVictoryScreenFinished VictoryScreenFinishedEvent;

	UFUNCTION(BlueprintCallable)
	void OnVictoryScreenFinished()
	{
		VictoryScreenFinishedEvent.Broadcast();
	}

	private UFUNCTION(BlueprintEvent)
	void BP_ShowPlayerWinner(EMinigameWinner Winner){}

	UFUNCTION()
	void ShowPlayerWinner(EMinigameWinner Winner)
	{
		BP_ShowPlayerWinner(Winner);
	}
}