class UIceSkatingBoostWidget : UHazeUserWidget
{
	UPROPERTY()
	int MaxCharges = 3;

	UPROPERTY()
	int NumCharges = 3;

	UPROPERTY()
	float BoostRefillPercent = 1.f;

	UFUNCTION(BlueprintEvent)
	void OnBoosted() {}

	UFUNCTION(BlueprintEvent)
	void FadeOutAndRemove() {}
}