class UFishAnimationComponent : UActorComponent
{
	float GapingTargetPercentage = 0.f;
	float GapingDuration = 5.f;
	bool bIsAgitated = false;
	float TargetTurnValue = 0.f;

	FHazeAcceleratedFloat GapingPct;
	FHazeAcceleratedFloat SwimmingAgitation;
	FHazeAcceleratedFloat SwimmingTurn;

	float BiteEndTime = 0.f;
	float LungeEndTime = 0.f;

	// Controls swimming blend space, where
	UFUNCTION(BlueprintPure)
	FVector2D GetSwimmingParams()
	{
		return FVector2D(SwimmingTurn.Value, SwimmingAgitation.Value);
	}

	UFUNCTION()
	void SetAgitated(bool bAgitated)
	{
		bIsAgitated = bAgitated;
	}

	UFUNCTION()
	void SetSwimTurn(const FRotator& PreviousWorldRotation)
	{
		// Set swimming blend space turning from target yaw in local space
		FRotator LocalDesiredRot = Owner.ActorTransform.InverseTransformVector(PreviousWorldRotation.Vector()).Rotation().GetNormalized();
		TargetTurnValue = FMath::GetMappedRangeValueClamped(FVector2D(-60.f, 60.f), FVector2D(1.f, -1.f), LocalDesiredRot.Yaw);
	}

	UFUNCTION()
	void SetGapingPercentage(float Percentage, float Duration = 5.f)
	{
		GapingTargetPercentage = Percentage;
		GapingDuration = Duration;
	}

	UFUNCTION(BlueprintPure)
	float GetGapingPercentage()
	{
		return GapingPct.Value;
	}

	UFUNCTION()
	void Bite()
	{
		BiteEndTime = Time::GetGameTimeSeconds() + 1.5f;
	}

	UFUNCTION(BlueprintPure)
	bool IsBiting()
	{
		return (Time::GetGameTimeSeconds() < BiteEndTime);
	}

	UFUNCTION()
	void Lunge()
	{
		LungeEndTime = Time::GetGameTimeSeconds() + 1.5f;
	}

	UFUNCTION(BlueprintPure)
	bool IsLunging()
	{
		return (Time::GetGameTimeSeconds() < LungeEndTime);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (IsBiting())
			GapingPct.AccelerateTo(0.f, 0.5f, DeltaTime);
		else
			GapingPct.AccelerateTo(GapingTargetPercentage, GapingDuration, DeltaTime);
		SwimmingAgitation.AccelerateTo(bIsAgitated ? 1.f : 0.f, 2.f, DeltaTime);
		if (IsLunging())
			SwimmingTurn.AccelerateTo(0.f, 0.5f, DeltaTime);
		else	
			SwimmingTurn.AccelerateTo(TargetTurnValue, 1.f, DeltaTime);
	}
}