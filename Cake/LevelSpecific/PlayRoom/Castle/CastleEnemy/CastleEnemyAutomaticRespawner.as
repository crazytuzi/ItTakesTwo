import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;

struct FTrackedCastleEnemy
{
	TSubclassOf<ACastleEnemy> Class;
	ACastleEnemy CurrentEnemy;
	USceneComponent StartPositionRelativeTo;
	FVector StartPosition;
	bool bIsDisabled = false;
	float PreviousSpawnGameTime = -1.f;
	float LastEnemyAliveGameTime = -1.f;
	bool bWaveTriggered = false;
};

class ACastleEnemyAutomaticRespawner : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UBillboardComponent Billboard;
    default Billboard.bIsEditorOnly = true;

	// Whether to automatically respawn the tracked enemies at the moment.
	UPROPERTY(BlueprintReadOnly, Category = "Automatic Respawner")
	bool bEnableRespawn = true;

	// Whether the enemies should be active at the start, or only once 'respawned' once.
	UPROPERTY(BlueprintReadOnly, Category = "Automatic Respawner")
	bool bStartWithActiveEnemy = true;

	// The enemies to automatically respawn
	UPROPERTY(BlueprintHidden, Category = "Automatic Respawner")
	TArray<ACastleEnemy> Enemies;

	// Minimum interval between enemies spawned by this spawner
	UPROPERTY(Category = "Automatic Respawner")
	float IntervalBetweenSpawns = 2.f;

	// Minimum interval between a specific enemy being respawned again
	UPROPERTY(Category = "Automatic Respawner")
	float PerEnemyRespawnInterval = 10.f;

	// Minimum delay after an enemy dies before it is able to be respawned
	UPROPERTY(Category = "Automatic Respawner")
	float PerEnemyRespawnDelay = 5.f;

	// Whether to use wave respawning system
	UPROPERTY(Category = "Automatic Respawner")
	bool bRespawnInWaves = false;

	// Minimum interval between all enemies respawning in a wave
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bRespawnInWaves", EditConditionHides))
	float EnemyWaveInterval = 10.f;

	// Minimum delay after killing all enemies that a new wave can spawn 
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bRespawnInWaves", EditConditionHides))
	float EnemyWaveDelay = 5.f;

	// Minimum delay after killing the first enemy that a new wave can spawn
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bRespawnInWaves", EditConditionHides))
	float FirstEnemyKillDelay = 0.f;

	// Whether respawn waves should happen even if all enemies aren't dead yet
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bRespawnInWaves", EditConditionHides))
	bool bWavesHappenBeforeAllEnemiesAreDead = true;

	// Whether to use randomized spawn points for enemies
	UPROPERTY(Category = "Automatic Respawner")
	bool bUseRandomSpawnPositions = false;

	// Spawn points to randomize between for enemies
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bUseRandomSpawnPositions", EditConditionHides))
	TArray<ACastleEnemySpawner> RandomSpawnPositions;

	// Delay between using the same random spawn position again
	UPROPERTY(Category = "Automatic Respawner", Meta = (EditCondition = "bUseRandomSpawnPositions", EditConditionHides))
	float PerSpawnPositionInterval = 2.f;

    // Position that the enemies always walk to before spreading out
    UPROPERTY(Meta = (MakeEditWidget, EditCondition="!bUseRandomSpawnPositions", EditConditionHides), Category = "Automatic Respawner")
    FTransform FunnelPosition;

	private TArray<FTrackedCastleEnemy> TrackedEnemies;
	private float GlobalSpawnTimer = 0.f;
	private int EnemiesSpawned = 0;
	private float LastAnyEnemyAliveGameTime = -1.f;
	private float LastAllEnemiesAliveGameTime = -1.f;
	private float LastWaveSpawnTime = -1.f;
	private TArray<float> SpawnPointUsedGameTime;

	/* Enable this spawner to respawn tracked enemies that die. */
	UFUNCTION()
	void EnableRespawn()
	{
		bEnableRespawn = true;
	}

	/* Disable any enemy respawns from this spawner. */
	UFUNCTION()
	void DisableRespawn()
	{
		bEnableRespawn = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl())
		{
			// Start tracking all the enemies we've been given
			for(ACastleEnemy Enemy : Enemies)
			{
				if (Enemy == nullptr)
					continue;
				AddEnemyToSpawner(Enemy, bStartWithActiveEnemy);
			}

			for (auto SpawnPoint : RandomSpawnPositions)
				SpawnPointUsedGameTime.Add(-1.f);
		}
		else if (!bStartWithActiveEnemy)
		{
			for (ACastleEnemy Enemy : Enemies)
				Enemy.DisableActor(this);
		}
	}

	UFUNCTION(Category = "Castle Enemy Automatic Respawner")
	void AddEnemyToSpawner(ACastleEnemy Enemy, bool bStartEnabled = false)
	{
		FTrackedCastleEnemy Track;
		Track.CurrentEnemy = Enemy;
		Track.Class = Enemy.Class;

		Track.StartPosition = Enemy.RootComponent.RelativeLocation;
		Track.StartPositionRelativeTo = Enemy.RootComponent.AttachParent;

		if (!bStartEnabled)
		{
			Track.bIsDisabled = true;
			Enemy.DisableActor(this);
		}
		else
		{
			float GameTime = Time::GetGameTimeSeconds();
			Track.PreviousSpawnGameTime = GameTime;
			Track.LastEnemyAliveGameTime = GameTime;
		}

		TrackedEnemies.Add(Track);
	}

    FVector GetFunnelLocation()
    {
        return ActorTransform.TransformPosition(FunnelPosition.Location);
    }

    ACastleEnemy SpawnSingleEnemy(TSubclassOf<ACastleEnemy> EnemyToSpawn, FTransform Spawn, FVector Funnel, FVector Loiter, AHazeActor LoiterSpline, UAnimSequence Animation)
    {
		ensure(HasControl());

		NetSpawnEnemy(EnemyToSpawn, Spawn, Funnel, Loiter, LoiterSpline, Animation);
		return SpawnSingleEnemyInternal(EnemyToSpawn, Spawn, Funnel, Loiter, LoiterSpline, Animation);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSpawnEnemy(TSubclassOf<ACastleEnemy> EnemyToSpawn, FTransform Spawn, FVector Funnel, FVector Loiter, AHazeActor LoiterSpline, UAnimSequence Animation)
	{
		if (!HasControl())
			SpawnSingleEnemyInternal(EnemyToSpawn, Spawn, Funnel, Loiter, LoiterSpline, Animation);
	}

    ACastleEnemy SpawnSingleEnemyInternal(TSubclassOf<ACastleEnemy> EnemyToSpawn, FTransform Spawn, FVector Funnel, FVector Loiter, AHazeActor LoiterSpline, UAnimSequence Animation)
    {
        auto Enemy = Cast<ACastleEnemy>(SpawnActor(EnemyToSpawn, Spawn.Location, Spawn.Rotator(), bDeferredSpawn = true));
        Enemy.MakeNetworked(this, EnemiesSpawned);
		FinishSpawningActor(Enemy);
        EnemiesSpawned += 1;

		Enemy.SetCapabilityActionState(n"SpawnLoiter", EHazeActionState::Active);
		Enemy.SetCapabilityAttributeVector(n"SpawnFunnelPosition", Funnel);
		Enemy.SetCapabilityAttributeVector(n"SpawnLoiterPosition", Loiter);
		if (Animation != nullptr)
		{
			Enemy.SetCapabilityAttributeObject(n"SpawnAnimation", Animation);
			Enemy.SetActorHiddenInGame(true);
		}

		if (LoiterSpline != nullptr)
			Enemy.SetCapabilityAttributeObject(n"SpawnLoiterSpline", UHazeSplineComponent::Get(LoiterSpline));

        return Enemy;
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetFakeSpawnDisabledEnemy(ACastleEnemy Enemy, FTransform Spawn, FVector Funnel, FVector Loiter, AHazeActor LoiterSpline, UAnimSequence Animation)
	{
		Enemy.EnableActor(this);
		Enemy.ActorLocation = Spawn.Location;
		Enemy.ActorRotation = Spawn.Rotator();

		Enemy.SetCapabilityActionState(n"SpawnLoiter", EHazeActionState::Active);
		Enemy.SetCapabilityAttributeVector(n"SpawnFunnelPosition", Funnel);
		Enemy.SetCapabilityAttributeVector(n"SpawnLoiterPosition", Loiter);
		if (Animation != nullptr)
		{
			Enemy.SetCapabilityAttributeObject(n"SpawnAnimation", Animation);
			Enemy.SetActorHiddenInGame(true);
		}

		if (LoiterSpline != nullptr)
			Enemy.SetCapabilityAttributeObject(n"SpawnLoiterSpline", UHazeSplineComponent::Get(LoiterSpline));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		float GameTime = Time::GetGameTimeSeconds();

		GlobalSpawnTimer -= DeltaTime;
		bool bCanSpawn = GlobalSpawnTimer < 0.f && bEnableRespawn;
		bool bAnyAlive = false;
		bool bAnyDead = false;

		for (FTrackedCastleEnemy& Track : TrackedEnemies)
		{
			bool bIsEnemyAlive = true;
			if (Track.CurrentEnemy == nullptr || Track.CurrentEnemy.bKilled)
				bIsEnemyAlive = false;
			if (Track.bIsDisabled)
				bIsEnemyAlive = false;

			if (bIsEnemyAlive)
			{
				//if(Track.CurrentEnemy.bHidden)
					//System::DrawDebugLine(Track.CurrentEnemy.ActorLocation, ActorLocation, LineColor = FLinearColor::Yellow, Thickness = 5.f);
				Track.LastEnemyAliveGameTime = GameTime;
				Track.bWaveTriggered = false;
				bAnyAlive = true;
			}
			else
			{
				bAnyDead = true;
			}

			if (!bIsEnemyAlive && bCanSpawn)
			{
				const bool bIntervalValid = Track.PreviousSpawnGameTime < 0.f || Time::GetGameTimeSince(Track.PreviousSpawnGameTime) > PerEnemyRespawnInterval;
				const bool bDelayValid = Track.LastEnemyAliveGameTime < 0.f || Time::GetGameTimeSince(Track.LastEnemyAliveGameTime) > PerEnemyRespawnDelay;
				const bool bWaveValid = !bRespawnInWaves || Track.bWaveTriggered;
				const bool bSpawnPointsValid = !bUseRandomSpawnPositions || AreAnySpawnPositionsAvailable();

				if (bIntervalValid && bDelayValid && bWaveValid && bSpawnPointsValid)
				{
					FVector CurrentFunnelLocation;
					FVector LoiterPosition;
					FTransform SpawnPosition;
					AHazeActor LoiterSpline;
					ACastleEnemySpawner UsedSpawner;
					UAnimSequence SpawnAnimation;

					FVector StartPosition = Track.StartPosition;
					if (Track.StartPositionRelativeTo != nullptr)
						StartPosition = Track.StartPositionRelativeTo.WorldTransform.TransformPosition(Track.StartPosition);

					if (bUseRandomSpawnPositions && RandomSpawnPositions.Num() != 0)
					{
						ACastleEnemySpawner SpawnAt = GetSpawnPositionToUse();
						UsedSpawner = SpawnAt;
						SpawnPosition = SpawnAt.GetSpawnTransform();
						CurrentFunnelLocation = SpawnAt.MakeRandomFunnelLocation();
						LoiterPosition = StartPosition;
						SpawnAnimation = SpawnAt.SpawnAnimation;

						if (SpawnAt.bUseSpline)
						{
							LoiterSpline = SpawnAt.SpawnMovementSpline;
							LoiterPosition = SpawnAt.MakeRandomLoiterLocation();
						}
					}
					else
					{
						SpawnPosition = ActorTransform;
						LoiterPosition = StartPosition;
						CurrentFunnelLocation = GetFunnelLocation();
					}

					ACastleEnemy NewEnemy;
					if (Track.bIsDisabled)
					{
						NewEnemy = Track.CurrentEnemy;
						NetFakeSpawnDisabledEnemy(NewEnemy, SpawnPosition, CurrentFunnelLocation, LoiterPosition, LoiterSpline, SpawnAnimation);
						Track.bIsDisabled = false;
					}
					else
					{
						NewEnemy = SpawnSingleEnemy(Track.Class, SpawnPosition, CurrentFunnelLocation, LoiterPosition, LoiterSpline, SpawnAnimation);
						Track.CurrentEnemy = NewEnemy;
					}

					if (UsedSpawner != nullptr)
						UsedSpawner.NetNotifyEnemySpawned(NewEnemy);

					bCanSpawn = false;
					GlobalSpawnTimer = IntervalBetweenSpawns;
					Track.bWaveTriggered = false;
				}
			}
		}

		if (bRespawnInWaves)
		{
			if (!bAnyAlive || bWavesHappenBeforeAllEnemiesAreDead)
			{
				const bool bWaveIntervalValid = LastWaveSpawnTime < 0.f || Time::GetGameTimeSince(LastWaveSpawnTime) > EnemyWaveInterval;
				const bool bWaveDelayValid = bWavesHappenBeforeAllEnemiesAreDead || LastAnyEnemyAliveGameTime < 0.f || Time::GetGameTimeSince(LastAnyEnemyAliveGameTime) > EnemyWaveDelay;
				const bool bWaveFirstEnemyKillDelayValid = LastAllEnemiesAliveGameTime < 0.f || Time::GetGameTimeSince(LastAllEnemiesAliveGameTime) > FirstEnemyKillDelay;

				if (bWaveIntervalValid && bWaveDelayValid && bWaveFirstEnemyKillDelayValid)
				{
					for (FTrackedCastleEnemy& Track : TrackedEnemies)
					{
						Track.bWaveTriggered = true;
					}

					LastWaveSpawnTime = GameTime;
				}
			}

			if (bAnyAlive)
				LastAnyEnemyAliveGameTime = GameTime;
			if (!bAnyDead)
				LastAllEnemiesAliveGameTime = GameTime;
		}
	}

	bool AreAnySpawnPositionsAvailable()
	{
		float GameTime = Time::GetGameTimeSeconds();
		for (int i = 0, Count = RandomSpawnPositions.Num(); i < Count; ++i)
		{
			float UseTime = SpawnPointUsedGameTime[i];
			if (UseTime >= 0.f && UseTime + PerSpawnPositionInterval >= GameTime)
				continue;
			if (!RandomSpawnPositions[i].bEnabled)
				continue;
			return true;
		}
		return false;
	}

	ACastleEnemySpawner GetSpawnPositionToUse()
	{
		float GameTime = Time::GetGameTimeSeconds();

		TArray<int> UsableIndices;
		for (int i = 0, Count = RandomSpawnPositions.Num(); i < Count; ++i)
		{
			float UseTime = SpawnPointUsedGameTime[i];
			if (UseTime >= 0.f && UseTime + PerSpawnPositionInterval >= GameTime)
				continue;
			if (!RandomSpawnPositions[i].bEnabled)
				continue;
			UsableIndices.Add(i);
		}

		int UseIndex = UsableIndices[FMath::RandRange(0, UsableIndices.Num()-1)];
		SpawnPointUsedGameTime[UseIndex] = GameTime;
		return RandomSpawnPositions[UseIndex];
	}
};
