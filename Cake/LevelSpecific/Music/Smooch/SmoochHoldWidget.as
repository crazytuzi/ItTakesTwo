class USmoochHoldWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, Category = "Hold")
	float SmoochProgress = 0.f;
}

class USmoochHoldButtonWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	void SetButtonScreenSpaceOffset(FVector2D Offset) {}

	UFUNCTION(BlueprintEvent)
	void FadeIn() {}

	UFUNCTION(BlueprintEvent)
	void FadeOut() {}
}