class UButtonMashWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Pulse()
	{
	}

	UFUNCTION(BlueprintEvent)
	void FadeOut()
	{
		// If this is not overriden, just destroy right away
		// But preferrably, we want some sort of animation here
		Destroy();
	}

	UFUNCTION()
	void Destroy()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION(BlueprintEvent)
	void SetPressesPerSecond(float PressesPerSecond)
	{
	}

	UFUNCTION(BlueprintEvent)
	void MakeExclusive()
	{
	}
}