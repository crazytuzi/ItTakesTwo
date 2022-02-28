import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;

class ACastleEnemyContinuousWaveSpawner : ACastleEnemySpawner
{
	UPROPERTY()
	TArray<TSubclassOf<ACastleEnemy>> EnemiesInWave;

	// How often each wave will be spawned
	UPROPERTY()	
	float EnemyWaveInterval = 8.f;
	UPROPERTY()
	float SpawnInterval = 0.5f;
	float WaveTimer = 0.f;


	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (!HasControl())
			return;

        if (Spawnings.Num() != 0)
        {
            FSpawnCycle& Cycle = Spawnings[0];
            Cycle.Timer += DeltaTime;

            if (Cycle.Timer >= Cycle.Interval)
            {
                Cycle.Timer -= Cycle.Interval;
                SpawnSingleEnemy(Cycle.EnemyToSpawn);
                Cycle.Remaining -= 1;
            }

            if (Cycle.Remaining <= 0)
                Spawnings.RemoveAt(0);
        }

		WaveTimer += DeltaTime;


		if (WaveTimer >= EnemyWaveInterval)
		{
			SpawnWave();
			WaveTimer = 0.f;
		}
	}

	UFUNCTION()
	void EnableSpawner()
	{
		bEnabled = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DisableSpawner()
	{
		bEnabled = false;
		SetActorTickEnabled(false);
		WaveTimer = 0.f;
	}

	void SpawnWave()
	{
		for (TSubclassOf<ACastleEnemy> CastleEnemy : EnemiesInWave)
		{
			SpawnEnemies(CastleEnemy, 1, SpawnInterval);
		}
	}
}