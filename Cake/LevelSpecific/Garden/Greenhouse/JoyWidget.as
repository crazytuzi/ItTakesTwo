class UJoyWidget : UHazeUserWidget
{	
	UPROPERTY()
	float OpacityWidget = 1;
	UPROPERTY()
	bool LeftStick;


	UFUNCTION()
	void RemoveWidget()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION(BlueprintEvent)
	void SetOpacity(float NewOpacity)
	{
		OpacityWidget = NewOpacity;
	}

	UFUNCTION(BlueprintEvent)
	void UpdateImage(bool NewStickSide)
	{
		LeftStick = NewStickSide;
	}
}

