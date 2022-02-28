import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawnerTeam;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Vino.AI.Scenepoints.ScenepointActor;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawnPoolComponent;
import Peanuts.Spline.SplinesContainer;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspDebugSlayerComponent;

event void FOnSpawnerDepleted(AWaspEnemySpawner Spawner);
event void FOnPostSpawn(AHazeActor Spawn, AWaspEnemySpawner Spawner);

const FName WaspSpawnerSpawnAction = n"Spawn";

UCLASS(Abstract)
class AWaspEnemySpawner : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UWaspSpawnerDummyComponent VisualizerDummyComponent; 

	UPROPERTY(Category = "Spawner")
	TSubclassOf<AHazeActor> SpawnClass;

	UPROPERTY(Category = "Spawner")
	bool IsActivated = false;

	UPROPERTY(Category = "Spawner")
	float PreSpawnDelay = 0.f;

	UPROPERTY(Category = "Spawner")
	float Interval = 10.f;

	// If > 0, we will not spawn until this long after last reported spawn from any active spawner.
	UPROPERTY(Category = "Spawner")
	float GlobalInterval = 0.f;

	UPROPERTY(Category = "Spawner")
	int MaxActiveEnemies = 0;

	// Every time we spawn, this many enemies will be spawned at once. Note that We never spawn unless it's ok to spawn this many enemies (due to maxactive etc).
	UPROPERTY(Category = "Spawner")
	int SpawnWaveSize = 1;

	UPROPERTY(Category = "Spawner")
	int SpawnPoolSize = 0;

	UPROPERTY(Category = "Spawner", NotVisible, BlueprintReadOnly)
	int SpawnedEnemies = 0;

	UPROPERTY(Category = "Spawner", NotVisible, BlueprintReadOnly)
	int ActiveEnemies = 0;

	UPROPERTY(Category = "Spawner")
	TArray<ASplineActor> EntrySplinePaths;

	UPROPERTY(Category = "Spawner")
	TArray<ASplineActor> FleeSplinePaths;

	UPROPERTY(Category = "Spawner")
	TArray<AScenepointActorBase> EntryScenepoints;

	UPROPERTY(Category = "Spawner")
	TArray<AWaspEnemySpawner> LinkedEnemySpawners;

	UPROPERTY(Category = "Spawner")
	int TriggerLinkedAtKills = 0;

	UPROPERTY(Category = "Spawner")
	float TriggerLinkedAtTime = 0.f;

	UPROPERTY(Category = "Spawner", NotVisible, BlueprintReadOnly)
	int KilledEnemies = 0;

	UPROPERTY(Category = "Spawner|Settings")
	UHazeComposableSettings Settings;

	UPROPERTY(Category = "Spawner|Settings", meta = (InlineEditConditionToggle))
	bool bOverride_TrackTargetWhenFollowingSpline = false;

	// If true, we look at best target when entering play (e.g. following spline or scenepoint)
	UPROPERTY(Category = "Spawner|Settings", meta = (EditCondition = "bOverride_TrackTargetWhenFollowingSpline"))
	bool bTrackTargetWhenFollowingSpline = false;

	UPROPERTY(Category = "Spawner|Settings", meta = (InlineEditConditionToggle))
	bool bOverride_EntryAcceleration = false;

	// Acceleration when entering play (e.g. following spline or scenepoint)
	UPROPERTY(Category = "Spawner|Settings", meta = (EditCondition = "bOverride_EntryAcceleration"))
	float EntryAcceleration = 1000.f;

	UPROPERTY(Category = "Spawner")
	FOnSpawnerDepleted OnSpawnerDepleted;

	UPROPERTY(Category = "Spawner")
	FOnPostSpawn OnPostSpawn;

	UPROPERTY(Category = "Spawner")
	TSubclassOf<UHazeAITeam> TeamClass = nullptr;

	// Team which all spawn will belong to
	UPROPERTY(Category = "Spawner", Transient, NotVisible, BlueprintReadOnly)
	UHazeAITeam Team;

	// Team which all spawners belong to
	UPROPERTY(Category = "Spawner", Transient, NotVisible, BlueprintReadOnly)
	UHazeAITeam AllSpawnersTeam;

	UPROPERTY(Category = "Health")
	float Health = 25.f;
	float MaxHealth = 25.f;
	default MaxHealth = Health;

	UPROPERTY(Category = "Health")
	TSubclassOf<UHealthBarWidget> HealthBarWidgetClass = nullptr;
	UHealthBarWidget MayHealthBar = nullptr;
	UHealthBarWidget CodyHealthBar = nullptr;

	UPROPERTY(Category = "Health")
	FVector HealthBarWorldOffset = FVector(0.f, 0.f, 500.f);

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UWaspSpawnPoolComponent SpawnPool = nullptr;

	float SpawnTime = 0.f;
	float TriggerLinkedCountDown = BIG_NUMBER;
	bool bHasActivatedLinkedSpawners = false;

	FScenepointContainer EntryScenepointsContainer;
	FSplinesContainer EntrySplinesContainer;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FleeSplinePaths = EntrySplinePaths;
		if ((SpawnPoolSize > 0) && (SpawnWaveSize > SpawnPoolSize))
			SpawnWaveSize = SpawnPoolSize;
		if ((MaxActiveEnemies > 0) && (SpawnWaveSize > MaxActiveEnemies))
			SpawnWaveSize = MaxActiveEnemies;
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Flee()
	{
		DeactivateSpawner();
	}

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!devEnsure(SpawnClass.IsValid(), "Spawner " + GetName() + " does not have a SpawnClass"))
			return;

		SpawnPool = WaspSpawnPoolStatics::GetOrCreateSpawnPool(SpawnClass, this);
		SpawnPool.OnSpawned.AddUFunction(this, n"OnSpawnedEnemy");

		SpawnTime = Time::GetGameTimeSeconds() + PreSpawnDelay;
		if (IsActivated)
			ActivateSpawner();
		
		SetEntryScenePoints(EntryScenepoints);

		for (ASplineActor Spline : EntrySplinePaths)
		{
			if (Spline != nullptr)
				EntrySplinesContainer.Splines.Add(Spline.Spline);
		}

		// Join common spawner team
		AllSpawnersTeam = JoinTeam(n"AllSpawnersTeam");
	}

	UFUNCTION()
	void SetEntryScenePoints(TArray<AScenepointActorBase> ScenePoints)
	{
		EntryScenepoints = ScenePoints; 
		EntryScenepointsContainer.Scenepoints.Empty(ScenePoints.Num());
		for (AScenepointActorBase Sp : EntryScenepoints)
		{
			if (Sp != nullptr)
				EntryScenepointsContainer.Scenepoints.Add(Sp.GetScenepoint());
		}
		EntryScenepointsContainer.Reset();
	}

	UFUNCTION()
	void SetEntrySplinePaths(TArray<ASplineActor> EntrySplines)
	{
		EntrySplinesContainer.Splines.Empty();

		for (ASplineActor Spline : EntrySplines)
		{
			if (Spline != nullptr)
				EntrySplinesContainer.Splines.Add(Spline.Spline);
		}
	}

	UFUNCTION()
	void ActivateSpawner()
	{
		IsActivated = true;		

		SpawnTime = Time::GetGameTimeSeconds() + PreSpawnDelay;

		if (TriggerLinkedAtTime > 0.f)
			if (TriggerLinkedCountDown == BIG_NUMBER)
				TriggerLinkedCountDown = TriggerLinkedAtTime;

		// Only ever tick on control side
		if (HasControl())
			SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		IsActivated = false;
		SetActorTickEnabled(false);
		HideHealthBar(Game::GetCody());
		HideHealthBar(Game::GetMay());
	}

  	UFUNCTION()
    void ResetSpawnCount()
    {
        SpawnedEnemies = 0;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CanSpawnEnemy())
		{
			SpawnEnemy();

			// Only try to spawn every once in a while
			SpawnTime = FMath::Max(Time::GetGameTimeSeconds() + Interval, SpawnTime);			
		}

		if (TriggerLinkedCountDown != BIG_NUMBER)
		{
			TriggerLinkedCountDown -= DeltaTime;
			if( TriggerLinkedCountDown <= 0.f)
				ActivateLinkedSpawners();
		}

		if ((TriggerLinkedAtKills > 0) && (KilledEnemies >= TriggerLinkedAtKills))
			ActivateLinkedSpawners();
	}

	bool CanSpawnEnemy()
	{
		float CurTime = Time::GetGameTimeSeconds();
		if (CurTime < SpawnTime)
			return false;

		if ((SpawnPoolSize > 0) && (SpawnedEnemies + SpawnWaveSize > SpawnPoolSize))
			return false;
		
		if ((MaxActiveEnemies > 0) && (ActiveEnemies + SpawnWaveSize > MaxActiveEnemies))
			return false;

		if ((GlobalInterval > 0.f) && (Time::GetGameTimeSeconds() < AllSpawnersTeam.GetLastActionTime(WaspSpawnerSpawnAction) + GlobalInterval))
			return false;

		return true;
	}

	void SpawnEnemy()
	{
		if (!HasControl())
			return;
		
		// Make sure we've got a spawn pool controlled on our side.
		if ((SpawnPool == nullptr) || !SpawnPool.IsMatchingControl(this))
		 	NetSetupSpawnPool();

		for (int i = 0; i < SpawnWaveSize; i++)
		{
			// Pool spawns enemy on both sides (or reuses existing available enemy)
			// When spawned, our OnSpawnedEnemy function will be called
			SpawnPool.SpawnWasp(this, GetSpawnParameters());
		}
	}

	UFUNCTION(BlueprintEvent)
	FWaspSpawnParameters GetSpawnParameters()
	{
		FWaspSpawnParameters Params;
		Params.Location = ActorLocation; 
		Params.Rotation = ActorRotation; 
		Params.Scenepoint = EntryScenepointsContainer.UseBestScenepoint();
		Params.Spline = Cast<UHazeSplineComponent>(EntrySplinesContainer.UseBestSpline(1.f));
		if (Params.Spline != nullptr)
		{
			Params.Location = Params.Spline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
			Params.Rotation = Params.Spline.GetRotationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
		}
		return Params;
	}

	UFUNCTION(NetFunction)
	void NetSetupSpawnPool()
	{
		if (SpawnPool != nullptr)
			SpawnPool.OnSpawned.Unbind(this, n"OnSpawnedEnemy");
		SpawnPool = WaspSpawnPoolStatics::GetOrCreateSpawnPool(SpawnClass, this);
		SpawnPool.OnSpawned.AddUFunction(this, n"OnSpawnedEnemy");
	}

	// Called on both sides in network right after wasp pool has spawned/respawned wasp. 
	// We do this instead of a netfunction here to make sure the spawn flow stays on the 
	// spawn pool actor channel.
	UFUNCTION(NotBlueprintCallable)
	void OnSpawnedEnemy(UObject Spawner, AHazeActor Enemy, FWaspSpawnParameters Params)
	{
		if (Spawner != this)
			return;

		if (!ensure(Enemy != nullptr))
			return;

		SpawnedEnemies++;
		ActiveEnemies++;
		AllSpawnersTeam.ReportAction(WaspSpawnerSpawnAction);

		// Check if we've completed additional wave
		if ((SpawnAdditionalRemaining > 0) && (--SpawnAdditionalRemaining == 0))
			AdditionalWaveDone();

		Team = Enemy.JoinTeam(FName(GetName()), TeamClass);

		UWaspRespawnerComponent RespawnComp = UWaspRespawnerComponent::Get(Enemy);
		RespawnComp.OnRespawnable.AddUFunction(this, n"OnEnemyDeath");

		PostSpawn(Enemy, Params);
		OnPostSpawn.Broadcast(Enemy, this);
	}

	// Called on both sides once enemy has been spawned
	UFUNCTION(BlueprintEvent)
	void PostSpawn(AHazeActor Enemy, FWaspSpawnParameters Params)
	{
		// TODO: This should really be stored in a separate movement component
		UWaspBehaviourComponent BehaviourComp = UWaspBehaviourComponent::Get(Enemy);
		if (BehaviourComp != nullptr)
			BehaviourComp.MovementBase = RootComponent.AttachParent;			
		Enemy.AttachToComponent(RootComponent.AttachParent, NAME_None, EAttachmentRule::KeepWorld);

		if (Settings != nullptr)
			Enemy.ApplySettings(Settings, this, EHazeSettingsPriority::Defaults);
		if (bOverride_TrackTargetWhenFollowingSpline)
			UWaspComposableSettings::SetbTrackTargetWhenFollowingSpline(Enemy, bTrackTargetWhenFollowingSpline, this, EHazeSettingsPriority::Defaults);
		if (bOverride_EntryAcceleration)
			UWaspComposableSettings::SetIdleAcceleration(Enemy, EntryAcceleration, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintEvent)
	FVector GetSpawnLocation()
	{
		return ActorLocation;
	}

	UFUNCTION(BlueprintEvent)
	FRotator GetSpawnRotation()
	{
		return ActorRotation;
	}

	UFUNCTION()
	void OnEnemyDeath(AHazeActor Enemy)
	{
		bool bSetSpawnTime = !CanSpawnEnemy();

		UWaspRespawnerComponent RespawnComp = UWaspRespawnerComponent::Get(Enemy);
		RespawnComp.OnRespawnable.Unbind(this, n"OnEnemyDeath");

		Enemy.LeaveTeam(FName(GetName()));

		KilledEnemies++;
		ActiveEnemies--;

		// Check if Spawner is depleted
		if (IsActivated && (SpawnPoolSize > 0) && (KilledEnemies >= SpawnPoolSize))
			DeactivateSpawner();

		if (!IsActivated && ActiveEnemies == 0)
			OnSpawnerDepleted.Broadcast(this);

		if (IsActivated && bSetSpawnTime)
			SpawnTime = Time::GetGameTimeSeconds() + PreSpawnDelay; // Allow immediate spawn
	}

	UFUNCTION()
	void ActivateLinkedSpawners()
	{
		if (bHasActivatedLinkedSpawners)
			return;
		if (!IsActivated)
			return;
		bHasActivatedLinkedSpawners = true;
		for (AWaspEnemySpawner LinkedSpawner : LinkedEnemySpawners)
		{
			if (LinkedSpawner != nullptr)
				LinkedSpawner.ActivateSpawner();
		}
	}

	UFUNCTION()
	void GetAllLinkedSpawners(TArray<AWaspEnemySpawner>& InOutSpawners)
	{
		for (AWaspEnemySpawner Spawner : InOutSpawners)
		{
			if (Spawner == this)
				return;
		}

		InOutSpawners.Add(this);

		for (AWaspEnemySpawner LinkedSpawner : LinkedEnemySpawners)
		{
			if (LinkedSpawner != nullptr)
				LinkedSpawner.GetAllLinkedSpawners(InOutSpawners);
		}
	}

	UFUNCTION()
	UScenepointComponent UseBestEntryScenepoint()
	{
		return EntryScenepointsContainer.UseBestScenepoint();
	}

	// Get all living actors this spawner has spawned
	UFUNCTION()
	TArray<AHazeActor> GetSpawnedActors()
	{
		TArray<AHazeActor> Spawn;
		if (Team == nullptr)
			return Spawn;
	
		for (AHazeActor Member : Team.GetMembers())
		{
			if ((Member != nullptr) && Member.IsA(SpawnClass))
				Spawn.Add(Member);
		}
		return Spawn;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (SpawnPool != nullptr)
			SpawnPool.OnSpawned.Unbind(this, n"OnSpawnedEnemy");

		DeactivateSpawner();
		TArray<AHazeActor> SpawnList = GetSpawnedActors();
		for (AHazeActor Spawn : SpawnList)
		{
			if (Spawn != nullptr)
				Spawn.DisableActor(nullptr); // Just in case destroying spawned actors might cause movement transitions desyncs.
		}
		LeaveTeam(n"AllSpawnersTeam");
	}

	int SpawnAdditionalEnemies = 0;
	int SpawnAdditionalRemaining = 0;
	float SpawnAdditionalIntervalDelta = 0.f; 
	int SpawnAdditionalWaveSizeDelta = 0;

	UFUNCTION()
	void SpawnAdditionalWave(int AdditionalEnemies, float OverrideInterval = -1.f, int OverrideWaveSize = -1)
	{
		if (AdditionalEnemies <= 0)
			return;

		// Expand spawn pool if it's limited
		if (SpawnPoolSize > 0)
			SpawnPoolSize += AdditionalEnemies;

		// Keep spawning additionals until we've spawned this many
	 	SpawnAdditionalRemaining += AdditionalEnemies;

		// Start spawning this wave immediately, regardless of previous or new interval
		SpawnTime = Time::GetGameTimeSeconds(); 

		// Add more enemies 
		SpawnAdditionalEnemies += AdditionalEnemies;
		MaxActiveEnemies += AdditionalEnemies;

		if (OverrideWaveSize > 0)
		{
			SpawnAdditionalWaveSizeDelta = OverrideWaveSize - SpawnWaveSize + SpawnAdditionalWaveSizeDelta;
			SpawnWaveSize = OverrideWaveSize;
		}

		if (OverrideInterval >= 0.f)
		{
			// Add current additional interval delta in case we trigger this when we already have an additional wave in progress
			SpawnAdditionalIntervalDelta = OverrideInterval - Interval + SpawnAdditionalIntervalDelta;
			Interval = OverrideInterval;
		}
	}
	
	void AdditionalWaveDone()
	{
		// Reset modified values
		MaxActiveEnemies -= SpawnAdditionalEnemies;
		SpawnAdditionalEnemies = 0;
		SpawnWaveSize -= SpawnAdditionalWaveSizeDelta;
		SpawnAdditionalWaveSizeDelta = 0;
		Interval -= SpawnAdditionalIntervalDelta;
		SpawnAdditionalIntervalDelta = 0.f;
	}

	UFUNCTION()
	void TakeDamage(float Damage)
	{
		Health -= Damage;
		if (Health > 0)
		{
			UpdateHealthBar(MayHealthBar);
			UpdateHealthBar(CodyHealthBar);
		}
		else
		{
			HideHealthBar(Game::GetCody());
			HideHealthBar(Game::GetCody());
		}
	}

	UFUNCTION()
	void ShowHealthBar(AHazePlayerCharacter Player)
	{
		if (HealthBarWidgetClass.IsValid() && IsActivated)
		{
			if (Health > 0.f)
			{
				if (MayHealthBar == nullptr && Player.IsMay())
					MayHealthBar = AddHealthBarWidget(Game::GetMay());
				if (CodyHealthBar == nullptr && Player.IsCody())
					CodyHealthBar = AddHealthBarWidget(Game::GetCody());
			}
		}
	}

	UHealthBarWidget AddHealthBarWidget(AHazePlayerCharacter Player)
	{
		if (!HealthBarWidgetClass.IsValid())
			return nullptr;

		UHealthBarWidget HealthBar = Cast<UHealthBarWidget>(Player.AddWidget(HealthBarWidgetClass));
		HealthBar.InitHealthBar(MaxHealth);

		HealthBar.AttachWidgetToComponent(RootComponent);
		HealthBar.SetWidgetWorldPosition(ActorLocation + HealthBarWorldOffset);
		return HealthBar;
	}

	void UpdateHealthBar(UHealthBarWidget HealthBar)
	{
		if (HealthBar == nullptr)
			return;

		HealthBar.SetHealthAsDamage(Health);
	}

	UFUNCTION()
	void HideHealthBar(AHazePlayerCharacter Player)
	{
		if (MayHealthBar != nullptr  && Player.IsMay())
		{
			Game::GetMay().RemoveWidget(MayHealthBar);
			MayHealthBar = nullptr;
		}
		if (CodyHealthBar != nullptr  && Player.IsCody())
		{
			Game::GetCody().RemoveWidget(CodyHealthBar);
			CodyHealthBar = nullptr;
		}
	}

	UFUNCTION(DevFunction)
	void DebugToggleWaspMatchVulnerability()
	{
#if TEST		
		AHazePlayerCharacter MatchWielder = Game::GetMay();
		if (MatchWielder == nullptr)
			return;

		UWaspDebugSlayerComponent SlayerComp = UWaspDebugSlayerComponent::GetOrCreate(MatchWielder);
		SlayerComp.bSlay = !SlayerComp.bSlay;
		PrintToScreenScaled((SlayerComp.bSlay ? "Wasps will now be instakilled by match hits" : "Wasps will no longer be damaged by match hits."), 5.f, FLinearColor::Red, 2.f);
#endif
	}
}

class UWaspSpawnerDummyComponent : UActorComponent
{
}
