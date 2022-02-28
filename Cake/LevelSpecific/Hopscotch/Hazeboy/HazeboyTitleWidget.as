class AHazeboyTitleWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	bool bWaitingForOpponent = false;

	UFUNCTION(BlueprintEvent)
	void OnHideTitleScreen() {}

	UFUNCTION(BlueprintEvent)
	void OnShowTitleScreen() {}
}