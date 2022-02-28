import Cake.LevelSpecific.Hopscotch.NumberCube;

class ARotateNumberCubesManager : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY(DefaultComponent)
    UBoxComponent BoxCollision;
	default BoxCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

    EHopScotchNumber CurrentHopscotchNumberToRotate;

    UPROPERTY()
    float RotateInterval = 1.f;

	UPROPERTY()
	float RotationDuration = 0.25f;

	float RotationTimer = 0.f;
	bool bShouldTickRotationTimer = false;
	bool bHasRotatedCube = false;
	
	float PauseTimer = 0.f;
	bool bShouldTickPauseTimer = false;
	
	float RotationToAdd = 90.f;
	
	UPROPERTY()
	int NumberOfCubesToRotate = 3;

	int RotationIndex = 0;

	UPROPERTY()
    TArray<ANumberCube> NumberCubeArray;

    TArray<AActor> ActorArray;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		RefillRotationTimer();
		RefillPauseTimer();
		// bShouldTickRotationTimer = true;
        
        CurrentHopscotchNumberToRotate = EHopScotchNumber::Hopscotch01;
    }

	UFUNCTION(CallInEditor)
	void FillNumberCubeArray()
	{
		TArray<ANumberCube> AllCubes;
		GetAllActorsOfClass(AllCubes);

		FTransform BoxTransform = BoxCollision.WorldTransform;
		FVector BoxExtent = BoxCollision.UnscaledBoxExtent;

		NumberCubeArray.Empty();
		for (ANumberCube Cube : AllCubes)
		{
			if (FMath::IsPointInBoxWithTransform(Cube.ActorLocation, BoxTransform, BoxExtent))
                NumberCubeArray.Add(Cube);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (bShouldTickRotationTimer)
		{
			RotationTimer -= DeltaTime;
			if (!bHasRotatedCube)
			{
				bHasRotatedCube = true;
				NetRotateCube(CurrentHopscotchNumberToRotate);
			}
			if (RotationTimer <= 0.f)
			{
				bShouldTickRotationTimer = false;
				bHasRotatedCube = false;
				bShouldTickPauseTimer = true;
				RefillRotationTimer();
				ChangeRotationIndex();
			}
		}
		
		if (bShouldTickPauseTimer)
		{
			PauseTimer -= DeltaTime;
			if (PauseTimer <= 0.f)
			{
				bShouldTickPauseTimer = false;
				bShouldTickRotationTimer = true;
				RefillPauseTimer();
			}
		}
	}

	void RefillRotationTimer()
	{
		RotationTimer = RotationDuration;
	}

	void RefillPauseTimer()
	{
		PauseTimer = RotateInterval;
	}

	void ChangeRotationIndex()
	{
		RotationIndex++;
		if (RotationIndex >= NumberOfCubesToRotate)
			RotationIndex = 0;

		switch (RotationIndex)
		{
			case 0:
				CurrentHopscotchNumberToRotate = EHopScotchNumber::Hopscotch01;
				break;
			
			case 1:
				CurrentHopscotchNumberToRotate = EHopScotchNumber::Hopscotch02;
				break;

			case 2:
				CurrentHopscotchNumberToRotate = EHopScotchNumber::Hopscotch03;
				break;
		}
	}

	UFUNCTION(NetFunction)
	void NetRotateCube(EHopScotchNumber CubesNmbr)
	{
		for (auto Cube : NumberCubeArray)
		{
			if (Cube.HopScotchNumber == CubesNmbr)
			{
				Cube.StartRotatingCube(RotationDuration);
			}
		}
	}

	UFUNCTION()
	void StartRotation()
	{
		bShouldTickRotationTimer = true;
	}
}