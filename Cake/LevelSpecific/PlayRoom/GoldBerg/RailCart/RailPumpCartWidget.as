class URailPumpCartWidget : UHazeUserWidget
{
	UPROPERTY()
	float FrontPumpRate = 0.f;

	UPROPERTY()
	float BackPumpRate = 0.f;

	UPROPERTY()
	bool bIsBoosting = false;

	UFUNCTION(BlueprintEvent)
	void OnButtonPressed() {}

	UFUNCTION(BlueprintEvent)
	void FadeAndDestroy() {}
}