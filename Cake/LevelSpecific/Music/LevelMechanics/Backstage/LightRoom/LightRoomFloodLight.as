class ALightRoomFloodLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LightMesh;

	UPROPERTY()
	UMaterialInterface RedMat;

	UPROPERTY()
	UMaterialInterface YellowMat;

	UPROPERTY()
	UMaterialInterface BlueMat;

	UPROPERTY()
	UMaterialInterface PurpleMat;

	UPROPERTY()
	UMaterialInterface OffMat;

	UPROPERTY()
	UNiagaraSystem DetachFX;

	UPROPERTY()
	FHazeTimeLike DetachLightTimeline;

	TArray<UMaterialInterface> MatArray;

	FVector StartLoc;
	FVector TargetLoc;

	float TurnOnDelay = 0.f;
	bool bShouldTickTurnOnDelay = false;

	float DetachDelay = 0.f;
	bool bShouldTickDetachDelay = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MatArray.Add(RedMat);
		MatArray.Add(YellowMat);
		MatArray.Add(BlueMat);
		MatArray.Add(PurpleMat);

		StartLoc = GetActorLocation();
		TargetLoc = StartLoc - FVector(0.f, 0.f, 30000.f);

		DetachLightTimeline.BindUpdate(this, n"DetachLightTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickTurnOnDelay)
		{
			TurnOnDelay -= DeltaTime;

			if (TurnOnDelay <= 0.f)
			{
				bShouldTickTurnOnDelay = false;
				TurnOnLight();
			}
		}

		if (bShouldTickDetachDelay)
		{
			DetachDelay -= DeltaTime;

			if (DetachDelay <= 0.f)
			{
				bShouldTickDetachDelay = false;
				DetachLight();
			}
		}
	}

	UFUNCTION()
	void TurnOnLightWithRandomColor()
	{
		TurnOnDelay = FMath::RandRange(0.f, 1.5f);
		bShouldTickTurnOnDelay = true;
	}

	void TurnOnLight()
	{
		int RandIndex = FMath::RandRange(0, MatArray.Num() - 1);
		LightMesh.SetMaterial(0, MatArray[RandIndex]);
	}

	UFUNCTION()
	void StartDetachingLight()
	{
		DetachDelay = FMath::RandRange(0.f, 1.f);
		bShouldTickDetachDelay = true;
	}

	void DetachLight()
	{
		Niagara::SpawnSystemAtLocation(DetachFX, GetActorLocation());
		DetachLightTimeline.PlayFromStart();
	}

	UFUNCTION()
	void DetachLightTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}
}