class URodeoInputButton : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	void BP_Success() {}

	UFUNCTION(BlueprintEvent)
	void BP_Fail() {}

	UFUNCTION(BlueprintEvent)
	void BP_SetInputIcon(FName ActionName) {}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateProgress(float Progress) {}
}