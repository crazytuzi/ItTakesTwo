import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Peanuts.Spline.SplineComponent;

event void FOnCastleEnemySpawned(ACastleEnemy Enemy);

struct FSpawnCycle
{
    TSubclassOf<ACastleEnemy> EnemyToSpawn;
    int Remaining = 0;
    float Interval = 1.f;
    float Timer = 0.f;
}

class ACastleEnemySpawner : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UBillboardComponent Billboard;
    default Billboard.bIsEditorOnly = true;
    //default Billboard.SetMaterial(Asset(""));

	/* Whether to enable the spawner at the start. */
	UPROPERTY(BlueprintReadOnly, Category = "Spawner")
	bool bEnabled = true;

	UPROPERTY(BlueprintReadOnly, Category = "Spawner", Meta = (InlineEditConditionToggle))
	bool bUseSpline = false;

	UPROPERTY(BlueprintReadOnly, Category = "Spawner", Meta = (EditCondition = "bUseSpline"))
	AHazeActor SpawnMovementSpline;

    // Position that the enemies always walk to before spreading out
    UPROPERTY(Meta = (MakeEditWidget), Category = "Spawner")
    FTransform FunnelPosition;

    // Radius of the funnel area for enemies walk to before spreading out
    UPROPERTY(Meta = (MakeEditWidget), Category = "Spawner")
    float FunnelRadius = 0.f;

    // Position around which the enemies will loiter if there is nothing to aggro to
    UPROPERTY(Meta = (MakeEditWidget), Category = "Spawner")
    FTransform LoiterPosition;

    // Position where enemies are actually spawned
    UPROPERTY(Meta = (MakeEditWidget), Category = "Spawner")
    FTransform SpawnPosition;

    // Radius of the loiter area for enemies to go to
    UPROPERTY(Meta = (MakeEditWidget), Category = "Spawner")
    float LoiterRadius = 500.f;

	UPROPERTY(Category = "Spawner")
	bool bMoveToLoiterAfterSpawning = true;

	UPROPERTY(Category = "Spawner")
	UAnimSequence SpawnAnimation;

	UPROPERTY()
	FOnCastleEnemySpawned OnEnemySpawned;

    int EnemiesSpawned = 0;
    TArray<FSpawnCycle> Spawnings;

	/* Enable this spawner. */
	UFUNCTION()
	void EnableSpawner()
	{
		bEnabled = true;
	}

	/* Enable this spawner. */
	UFUNCTION()
	void DisableSpawner()
	{
		bEnabled = false;
	}

    // Spawn an amount of enemies spaced by a particular interval
    UFUNCTION()
    void SpawnEnemies(TSubclassOf<ACastleEnemy> EnemyToSpawn, int Amount = 1, float Interval = 1.f)
    {
		if (!HasControl())
			return;

        FSpawnCycle Cycle;
        Cycle.Remaining = Amount;
        Cycle.Interval = Interval;
        Cycle.Timer = Spawnings.Num() == 0 ? Interval : 0.f;
        Cycle.EnemyToSpawn = EnemyToSpawn;
        Spawnings.Add(Cycle);

        SetActorTickEnabled(true);
    }

    ACastleEnemy SpawnSingleEnemy(TSubclassOf<ACastleEnemy> EnemyToSpawn)
    {
		ensure(HasControl());
		FVector Loiter = MakeRandomLoiterLocation();
		FVector Funnel = MakeRandomFunnelLocation();

		NetSpawnEnemy(EnemyToSpawn, Funnel, Loiter);
		return SpawnSingleEnemyInternal(EnemyToSpawn, Funnel, Loiter);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSpawnEnemy(TSubclassOf<ACastleEnemy> EnemyToSpawn, FVector Funnel, FVector Loiter)
	{
		if (!HasControl())
			SpawnSingleEnemyInternal(EnemyToSpawn, Funnel, Loiter);
	}

    ACastleEnemy SpawnSingleEnemyInternal(TSubclassOf<ACastleEnemy> EnemyToSpawn, FVector Funnel, FVector Loiter)
    {
        if (!EnemyToSpawn.IsValid())
        {
            devEnsure(false, "Invalid enemy class on castle enemy spawner.");
            return nullptr;
        }

		FTransform EnemyTransform = GetSpawnTransform();
        auto Enemy = Cast<ACastleEnemy>(SpawnActor(EnemyToSpawn, EnemyTransform.Location, EnemyTransform.Rotation.Rotator(), bDeferredSpawn = true));
        Enemy.MakeNetworked(this, EnemiesSpawned);
		FinishSpawningActor(Enemy);

		if (bMoveToLoiterAfterSpawning)
		{
        	Enemy.SetCapabilityActionState(n"SpawnLoiter", EHazeActionState::Active);
        	Enemy.SetCapabilityAttributeVector(n"SpawnFunnelPosition", Funnel);
        	Enemy.SetCapabilityAttributeVector(n"SpawnLoiterPosition", Loiter);
			if (SpawnAnimation != nullptr)
			{
				Enemy.SetCapabilityAttributeObject(n"SpawnAnimation", SpawnAnimation);
				Enemy.SetActorHiddenInGame(true);
			}

			if (SpawnMovementSpline != nullptr && bUseSpline)
				Enemy.SetCapabilityAttributeObject(n"SpawnLoiterSpline", UHazeSplineComponent::Get(SpawnMovementSpline));
		}

        EnemiesSpawned += 1;
		OnEnemySpawned.Broadcast(Enemy);
        return Enemy;
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetNotifyEnemySpawned(ACastleEnemy Enemy)
	{
		OnEnemySpawned.Broadcast(Enemy);
	}

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
        else
        {
            SetActorTickEnabled(false);
        }
    }

    FVector MakeRandomLoiterLocation()
    {
        FVector LoiterAt = ActorTransform.TransformPosition(LoiterPosition.Location);

		if (bUseSpline && SpawnMovementSpline != nullptr)
		{
			UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(SpawnMovementSpline);
			if (SplineComp != nullptr)
			{
				LoiterAt = SplineComp.GetLocationAtDistanceAlongSpline(SplineComp.GetSplineLength(), ESplineCoordinateSpace::World);
			}
		}

        LoiterAt += (FMath::VRand() * FVector(1.f, 1.f, 0.f)) * LoiterRadius;
        return LoiterAt;
    }

    FVector MakeRandomFunnelLocation()
    {
        FVector FunnelThrough = ActorTransform.TransformPosition(FunnelPosition.Location);
        FunnelThrough += (FMath::VRand() * FVector(1.f, 1.f, 0.f)) * FunnelRadius;
        return FunnelThrough;
    }

    FTransform GetSpawnTransform()
    {
        return SpawnPosition * ActorTransform;
    }
}