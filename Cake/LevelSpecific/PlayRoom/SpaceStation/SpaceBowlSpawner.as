import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceBowl;

UCLASS(Abstract)
class ASpaceBowlSpawner : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SpawnerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LandingPoint;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASpaceBowl> SpaceBowlClass;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnHorizontalTimeLike;
	default SpawnHorizontalTimeLike.Duration = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnVerticalTimeLike;
	default SpawnVerticalTimeLike.Duration = 1.f;

	FVector CurSpawnLocation;

	UPROPERTY()
	ASpaceBowl CurrentBowl;
	bool bSpawningNewBowl = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnHorizontalTimeLike.BindUpdate(this, n"UpdateSpawnHorizontal");
		SpawnHorizontalTimeLike.BindFinished(this, n"FinishSpawnHorizontal");
		SpawnVerticalTimeLike.BindUpdate(this, n"UpdateSpawnVertical");
		SpawnVerticalTimeLike.BindFinished(this, n"FinishSpawnVertical");

		SpawnVerticalTimeLike.SetPlayRate(2.f);
		CurrentBowl.OnSpaceBowlDestroyed.AddUFunction(this, n"RespawnSpaceBowl");
		// RespawnSpaceBowl();
	}

	UFUNCTION()
	void RespawnSpaceBowl()
	{
		// CurrentBowl = Cast<ASpaceBowl>(SpawnActor(SpaceBowlClass, SpawnPoint.WorldLocation, SpawnPoint.WorldRotation));
		// CurrentBowl.RespawnSpaceBowl();
		SpawnHorizontalTimeLike.PlayFromStart();
		SpawnVerticalTimeLike.PlayFromStart();
		bSpawningNewBowl = true;
		// CurrentBowl.OnSpaceBowlDestroyed.AddUFunction(this, n"RespawnSpaceBowl");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bSpawningNewBowl && CurrentBowl != nullptr)
		{
			CurrentBowl.SetActorLocation(CurSpawnLocation);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateSpawnHorizontal(float CurValue)
	{
		FVector HorizontalSpawnLoc = FMath::Lerp(SpawnPoint.WorldLocation, LandingPoint.WorldLocation, CurValue);
		CurSpawnLocation.X = HorizontalSpawnLoc.X;
		CurSpawnLocation.Y = HorizontalSpawnLoc.Y;
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishSpawnHorizontal()
	{
		bSpawningNewBowl = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateSpawnVertical(float CurValue)
	{
		CurSpawnLocation.Z = FMath::Lerp(SpawnPoint.WorldLocation.Z, SpawnPoint.WorldLocation.Z + 150.f, CurValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishSpawnVertical()
	{
		
	}
}