class UClockworkLastBossFreeFallRewindComponent : UActorComponent
{
	TArray<FTransform> TransformStampsArray;
	bool bShouldStampTransform = false;
	float TimerMax = 1.f;
	float Timer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldStampTransform)
			return;

		Timer -= DeltaTime;
		
		if (Timer <= 0.f)
		{
			Timer = TimerMax;
			TransformStampsArray.Add(Owner.GetActorTransform());
		}
	}

	UFUNCTION()
	void StartStampingTransform()
	{
		bShouldStampTransform = true;
		Timer = 0.f;
		TransformStampsArray.Empty();
	}

	UFUNCTION()
	void StopStampingFreeFallTransform()
	{
		bShouldStampTransform = false;
	}
}