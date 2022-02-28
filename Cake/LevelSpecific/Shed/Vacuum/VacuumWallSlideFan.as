class AVacuumWallSlideFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FanRoot;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	UStaticMeshComponent FanMesh;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	USceneComponent WallRoot1;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	USceneComponent WallRoot2;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	USceneComponent WallRoot3;

	UPROPERTY(DefaultComponent, Attach = WallRoot1)
	USceneComponent WallFlipRoot1;

	UPROPERTY(DefaultComponent, Attach = WallRoot2)
	USceneComponent WallFlipRoot2;

	UPROPERTY(DefaultComponent, Attach = WallRoot3)
	USceneComponent WallFlipRoot3;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothSyncRot;
	
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncRotationRate;

	UPROPERTY(DefaultComponent, Attach = FanMesh)
	UHazeAkComponent FanHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFanAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	bool bValveControlled = true;
	float ValveTurnDirection = 0.f;

	float CurrentRotation = 0.f;
	float CurrentRotationRate = 0.f;

	FRotator PlatformRotation;

	UPROPERTY(NotEditable)
	float FanRootRot;

	bool bWall1FaceRight = false;
	bool bWall2FaceRight = false;
	bool bWall3FaceRight = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformRotation = WallRoot1.WorldRotation;
		FanHazeAkComp.HazePostEvent(StartFanAudioEvent);

		FanRoot.SetRelativeRotation(FRotator(0.f, 0.f, 30.f));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WallRoot1.SetWorldRotation(PlatformRotation);
		WallRoot2.SetWorldRotation(PlatformRotation);
		WallRoot3.SetWorldRotation(PlatformRotation);

		if (HasControl())
		{
			if (bValveControlled)
			{
				if (ValveTurnDirection == 0.f)
				{
					CurrentRotationRate = FMath::FInterpTo(CurrentRotationRate, 0.f, DeltaTime, 1.75f);
				}
				else
				{
					CurrentRotationRate += 15.f * ValveTurnDirection * DeltaTime;
				}

				CurrentRotationRate = FMath::Clamp(CurrentRotationRate, -30.f, 30.f);

				FanRoot.AddLocalRotation(FRotator(0.f, 0.f, CurrentRotationRate * DeltaTime));
			}
			else
			{
				CurrentRotationRate += 15.f * DeltaTime;
				CurrentRotationRate = FMath::Clamp(CurrentRotationRate, 0.f, 35.f);
				FanRoot.AddLocalRotation(FRotator(0.f, 0.f, CurrentRotationRate * DeltaTime));
			}
			
			SmoothSyncRot.SetValue(FanRoot.RelativeRotation);
			SmoothSyncRotationRate.Value = FMath::GetMappedRangeValueClamped(FVector2D(-30.f, 30.f), FVector2D(-1.f, 1.f), CurrentRotationRate);
		}
		else
		{
			FanRoot.SetRelativeRotation(SmoothSyncRot.Value);
		}

		if(FanHazeAkComp.IsGameObjectRegisteredWithWwise())
			FanHazeAkComp.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_WallSlideFan_RotationRate", SmoothSyncRotationRate.Value);

		FanRootRot = FanRoot.RelativeRotation.Roll;

		// Wall 1
		if (FanRootRot < -120.f || FanRootRot > 60.f)
		{
			if (!bWall1FaceRight)
			{
				bWall1FaceRight = true;
				BP_RotateWall1(true);
			}
		}
		else
		{
			if (bWall1FaceRight)
			{
				bWall1FaceRight = false;
				BP_RotateWall1(false);
			}
		}

		// Wall 2
		if (FanRootRot < 0.f)
		{
			if (!bWall2FaceRight)
			{
				bWall2FaceRight = true;
				BP_RotateWall2(true);
			}
		}
		else
		{
			if (bWall2FaceRight)
			{
				bWall2FaceRight = false;
				BP_RotateWall2(false);
			}
		}
		
		// Wall3
		if (FanRootRot < 120.f && FanRootRot > -60)
		{
			if (!bWall3FaceRight)
			{
				bWall3FaceRight = true;
				BP_RotateWall3(true);
			}
		}
		else
		{
			if (bWall3FaceRight)
			{
				bWall3FaceRight = false;
				BP_RotateWall3(false);
			}
		}
		
	}

	void UpdateRotation(float RotAlpha)
	{
		CurrentRotation = FMath::Lerp(0.f, 360.f, RotAlpha/100.f);
	}

	UFUNCTION()
	void StartRotating()
	{
		bValveControlled = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_RotateWall1(bool bFaceRight) {}

	UFUNCTION(BlueprintEvent)
	void BP_RotateWall2(bool bFaceRight) {}

	UFUNCTION(BlueprintEvent)
	void BP_RotateWall3(bool bFaceRight) {}
}