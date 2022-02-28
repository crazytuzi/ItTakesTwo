class UClownBalloonBridgerotation : USceneComponent
{
	UPROPERTY()
	float EndAngle;

	UPROPERTY()
	FHazeTimeLike TimeLike;

	default TimeLike.bLoop = true;
	default TimeLike.bSyncOverNetwork = true;
	default TimeLike.Duration = 1;
	default TimeLike.SyncTag = n"Oscillation";

	UPROPERTY()
	bool bAllowOscillation;

	UPROPERTY()
	float RandomMaxTimeUntilStart = 0.01f;
	
	float StartAngle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartAngle = Owner.ActorRotation.Pitch;
		
		if (HasControl())
		{
			System::SetTimer(this, n"NetStartOscillation", FMath::RandRange(0.f, RandomMaxTimeUntilStart), false);
		}
	}

	UFUNCTION(NetFunction)
	void NetStartOscillation()
	{
		TimeLike.BindUpdate(this, n"UpdateTimeLike");
		TimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		if (!bAllowOscillation)
			return;

		float Yaw = FMath::Lerp(StartAngle, EndAngle, Duration);
		FRotator Rotation = Owner.ActorRotation;
		Rotation.Pitch = Yaw;

		Owner.SetActorRotation(Rotation);
	}
}