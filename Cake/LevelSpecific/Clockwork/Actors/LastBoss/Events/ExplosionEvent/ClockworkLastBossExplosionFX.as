class AClockworkLastBossExplosionFX : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FxComp;

	float ScrubValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void CurrentScrubValue(float NewScrubValue)
	{
		ScrubValue = NewScrubValue;
		//TimeChange(FMath::GetMappedRangeValueClamped(FVector2D(0.f, 7.f), FVector2D(0.f, 1.f), ScrubValue));
	}

	UFUNCTION(BlueprintEvent)
	void TimeChange(float Time)
	{
		
	}
}