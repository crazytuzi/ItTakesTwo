class AClockworkLastBossScrubbedSpotlightController : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	ASpotLight ConnectedSpotlight;

	UPROPERTY()
	float MinIntensity = 5.f;

	UPROPERTY()
	float MaxIntensity = 15.f;

	float ScrubTime = 0.f;

	UFUNCTION()
	void SetScrubTime(float NewScrubTime)
	{
		if (NewScrubTime >= 1.f && NewScrubTime <= 2.f) 
			ScrubTime = FMath::GetMappedRangeValueClamped(FVector2D(1.f, 2.f), FVector2D(MinIntensity, MaxIntensity), NewScrubTime);
		else
			ScrubTime = 5.f;

		ConnectedSpotlight.SpotLightComponent.SetIntensity(ScrubTime);
	}
}