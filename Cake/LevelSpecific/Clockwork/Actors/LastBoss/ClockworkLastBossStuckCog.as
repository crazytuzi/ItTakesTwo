class AClockworkLastBossStuckCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CogMesh;

	UPROPERTY()
	bool bIsMasterCog = false;

	UPROPERTY()
	bool bReverse = false;

	float CurrentTimeControlSpeed = 0.f;

	float RotationSpeed = 50.f;
	float TwitchMultiplier = 1.f;

	float Size = 0.f;
	default Size = ActorScale3D.Size();

	FRotator StartRot;
	FRotator TargetRot;

	bool bShouldRotateCog = false;

	UPROPERTY()
	AClockworkLastBossStuckCog MasterCog;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Size = GetActorScale3D().Size();
		
		if (!bIsMasterCog)
		{
			TArray<AClockworkLastBossStuckCog> TempArray;
			GetAllActorsOfClass(TempArray);

			for (AClockworkLastBossStuckCog Cog : TempArray)
			{
				if (Cog.bIsMasterCog)
				{
					MasterCog = Cog;
				}
			}

			RotationSpeed = (MasterCog.Size * MasterCog.RotationSpeed) / Size;
			TwitchMultiplier = (MasterCog.Size * MasterCog.TwitchMultiplier) / Size;

			if (bReverse)
			{
				RotationSpeed *= -1.f;
				TwitchMultiplier *= -1.f;
			}
		}
		
		StartRot = MeshRoot.RelativeRotation;
		TargetRot = StartRot + (FRotator(0.f, 0.f, 10.f * TwitchMultiplier)); 

		StartRotatingCogs(RotationSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldRotateCog)
			MeshRoot.AddLocalRotation(FRotator(0.f, 0.f, RotationSpeed * CurrentTimeControlSpeed * DeltaTime));
	}

	UFUNCTION(CallInEditor)
	void SwapCogRotation()
	{
		bReverse = !bReverse;
	}

	UFUNCTION()
	void StartRotatingCogs(float NewSpeed)
	{
		RotationSpeed = NewSpeed;
		bShouldRotateCog = true;
	}
}