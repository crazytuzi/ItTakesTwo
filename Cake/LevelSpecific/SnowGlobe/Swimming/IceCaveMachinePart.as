class AIceCaveMachinePart : AHazeActor
{
	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlatformMovingSound;

	UPROPERTY()
	UCurveFloat AnimationCurve;

	UPROPERTY()
	float PlayRate = 1.0f;

	UPROPERTY()
	FTransform EndTransform;

	UPROPERTY()
	FRotator EndRotation;

	UPROPERTY()
	bool DoProgressAnimation = false;

	UPROPERTY()
	bool StartOnMax = false;

	UPROPERTY()
	float ConstantSpeed = 1.0f;


	UPROPERTY(NotEditable)
	USceneComponent MovingRootRef;

	UPROPERTY(NotEditable)
	UStaticMeshComponent StaticMeshRef;

	UPROPERTY(NotEditable)
	UHazeAkComponent HazeAkRef;


	FTransform StartTransform;
	FRotator StartRotation;
	float Progress;

	bool PostPlatformMovingSoundOnce = false;

	UFUNCTION()
	void SetupStartTransforms()
	{
		StartTransform = MovingRootRef.WorldTransform;
		EndTransform = EndTransform * MovingRootRef.WorldTransform;

		StartRotation = MovingRootRef.GetRelativeRotation();

		StartTransform.NormalizeRotation();
		EndTransform.NormalizeRotation();
	}

	UFUNCTION()
	void MachineUpdateParts(float MachineProgress, bool MachineIsActivated)
	{
		if (MachineIsActivated && StartOnMax)
		{
			float DeltaTime = GetActorDeltaSeconds();
			Progress += ConstantSpeed * DeltaTime;
		}
		else if(!MachineIsActivated && DoProgressAnimation)
		{
			Progress = MachineProgress;
		}
		else
		{
			return;
		}

		float Alpha = Progress * PlayRate;
		if (Alpha > 1.0f)
		{
			Alpha = FMath::Fractional(Alpha);
		}

		float CurveAlpha = AnimationCurve.GetFloatValue(Alpha);


		FTransform NewTransform;
		NewTransform.Blend(StartTransform, EndTransform, CurveAlpha);

		FRotator LerpedRotation = StartRotation + ((EndRotation - StartRotation) * Alpha);

		NewTransform.SetRotation(NewTransform.Rotation * LerpedRotation.Quaternion());
		
		MovingRootRef.WorldTransform = NewTransform;


		HazeAkRef.SetRTPCValue("Rtpc_SnowGlobe_Lake_MachinePart_Moving", CurveAlpha);

		if (!PostPlatformMovingSoundOnce)
		{
			PostPlatformMovingSoundOnce = true;
			HazeAkRef.HazePostEvent(PlatformMovingSound);
		}

	}
}
