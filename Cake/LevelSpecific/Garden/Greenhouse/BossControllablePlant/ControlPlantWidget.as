class UControlPlantWidget : UHazeUserWidget
{	
	UFUNCTION()
	void Destroy()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION(BlueprintEvent)
	void SetProgress(float Progress)
	{
		
	}
}
