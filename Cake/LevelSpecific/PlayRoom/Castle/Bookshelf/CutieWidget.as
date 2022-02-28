class UCutieWidget : UHazeUserWidget
{	
	UPROPERTY()
	float OpacityWidget = 0;
	UPROPERTY()
	bool LeftStick;

	UFUNCTION(BlueprintEvent)
	void SetOpacityInstantly(float NewOpacity)
	{
		OpacityWidget = NewOpacity;
	}

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
	void UpdateImage()
	{
	}
}
