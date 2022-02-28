import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;

class ACastleEnemyContinuousSpawner : ACastleEnemySpawner
{
	/* Pick a random enemy type from this list to spawn if the enemy dies. */
	UPROPERTY(Category = "Continous Spawner")
	TArray<TSubclassOf<ACastleEnemy>> RandomEnemyType;

	/* Minimum interval between enemies spawned from this spawner. */
	UPROPERTY(Category = "Continous Spawner")
	float MinimumIntervalBetweenSpawns = 10.f;

	/* Minimum delay after the enemy dies before spawning a new one. */
	UPROPERTY(Category = "Continous Spawner")
	float MinimumReSpawnDelay = 5.f;

	float PreviousSpawnGameTime = -1.f;
	float LastEnemyAliveGameTime = -1.f;
	ACastleEnemy CurrentEnemy;
	bool bSpawnedAnyEnemies = false;

	void EnableSpawner() override
	{
		Super::EnableSpawner();
		if (!bSpawnedAnyEnemies)
			SpawnNewEnemy();
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bEnabled && HasControl())
			SpawnNewEnemy();
	}

	void SpawnNewEnemy()
	{
		TSubclassOf<ACastleEnemy> EnemyType;
		if (bSpawnedAnyEnemies)
			EnemyType = RandomEnemyType[FMath::RandRange(0, RandomEnemyType.Num()-1)];
		else
			EnemyType = RandomEnemyType[0];

		CurrentEnemy = SpawnSingleEnemy(EnemyType);
		PreviousSpawnGameTime = Time::GetGameTimeSeconds();
		bSpawnedAnyEnemies = true;
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (!bEnabled)
			return;
		if (!HasControl())
			return;

		if (CurrentEnemy == nullptr || CurrentEnemy.bKilled)
		{
			const bool bIntervalValid = Time::GetGameTimeSince(PreviousSpawnGameTime) > MinimumIntervalBetweenSpawns;
			const bool bDelayValid = Time::GetGameTimeSince(LastEnemyAliveGameTime) > MinimumReSpawnDelay;

			if (bIntervalValid && bDelayValid)
				SpawnNewEnemy();
		}
		else
		{
			LastEnemyAliveGameTime = Time::GetGameTimeSeconds();
		}
	}
};