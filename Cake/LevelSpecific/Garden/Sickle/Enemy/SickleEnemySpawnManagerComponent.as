import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

event void FSickleEnemySpawnManagerLostEnemySignature(int EnemiesLeft);
event void FSickleEnemySpawnManagerSpawnedEnemySignature(ASickleEnemy Enemy);
event void FSickleEnemySpawnManagerFinishedSignature(AHazeActor SpawnManager);

/*
 * This component takes care of spawning enemies as long as the owner of the component is not killed
 */

 bool BindAreaOnCompleteEvent(ASickleEnemyMovementArea Area, AHazeActor ComponentOwner)
 {
	if(Area == nullptr)
		return false;

	if(ComponentOwner == nullptr)
		return false; 

	auto SpawnManager = USickleEnemySpawnManagerComponent::Get(ComponentOwner);
	if(SpawnManager == nullptr)
		return false;

	SpawnManager.AreasWaitingToFinish.AddUnique(Area);
	return true;
 }

 FString GetSpawnManagerDebugInfo(ASickleEnemyMovementArea Area, AHazeActor ComponentOwner, bool bExtendedEnemyInfo)
 {
	if(Area == nullptr)
		return "Invalid";

	if(ComponentOwner == nullptr)
		return "Invalid";
	
	auto SpawnManager = USickleEnemySpawnManagerComponent::Get(ComponentOwner);
	if(SpawnManager == nullptr)
		return "Invalid";

	return SpawnManager.GetDebugInfo(bExtendedEnemyInfo);
 }

 bool ShouldDelaySickleEnemyDestruction(ASickleEnemy SickleEnemy)
 {
 	return UHazeDisableComponent::Get(SickleEnemy) != nullptr || USickleEnemySpawnManagerComponent::Get(SickleEnemy) != nullptr;
 }

struct FSickleEnemySpawnManagerWave
{
	UPROPERTY(Category = "Spawning")
	TArray<TSubclassOf<ASickleEnemy>> EnemyTypesToSpawn;
}

struct FSickleEnemySpawnManagerComponentPositionData
{
	UPROPERTY(Category = "Spawning")
	FName Level = n"AlternativSpawning";

	UPROPERTY(Category = "Spawning")
	TArray<AActor> SpawnPositions;
}

UCLASS(hidecategories="ComponentReplication Mobile Activation Cooking AssetUserData Collision")
class USickleEnemySpawnManagerComponent : UActorComponent
{
	// The enemies spawned from this manager will belong to this spawn area
	// If this component is on a sickle enemy, the move area from the owner will be used
	UPROPERTY(EditInstanceOnly, Category = "Spawning")
	ASickleEnemyMovementArea SpawnArea;

	UPROPERTY(Category = "Spawning")
	bool bSpawnWaves = false;

	// If true, the 'EnableSpawning' needs to be called for this to activate
	UPROPERTY(Category = "Spawning")
	bool bStartDisabled = false;

	// Type to spawn
	UPROPERTY(Category = "Spawning", meta = (EditCondition = "!bSpawnWaves"))
	TSubclassOf<ASickleEnemy> EnemyType;

	/* Every time a wave is cleared, the next wave will trigger
	*/
	UPROPERTY(Category = "Spawning", meta = (EditCondition = "bSpawnWaves"))
	TArray<FSickleEnemySpawnManagerWave> EnemyWaves;

	/* If the enemy count is less then this, they will spawn up to the max amount.
	 * If maxamount is less then this, then this is the max amount
	*/
	UPROPERTY(Category = "Spawning", meta = (EditCondition = "!bSpawnWaves", ClampMin = "0", ClampMax = "10", UIMin = "0", UIMax = "10"))
	int MinAmont = 0;

	UPROPERTY(Category = "Spawning", meta = (EditCondition = "!bSpawnWaves", ClampMin = "0", ClampMax = "10", UIMin = "0", UIMax = "10"))
	int MaxAmount = 0;

	// How long after the min amount has been reached until the first enemy is spawned
	UPROPERTY(Category = "Spawning")
	float InitialSpawnDelay = 0;

	/* Will spawn this amount without delay the first time it spawns
	 * Use -1 to spawn the max amount as the inital amount
	 * This will not consume from the spawnpool
	*/
	UPROPERTY(Category = "Spawning", meta = (EditCondition = "!bSpawnWaves"))
	int InitialSpawnAmount = 0;

	// How long after an enemy is spawned, can the next one spawn
	UPROPERTY(Category = "Spawning")
	float DelayBetweenSpawns = 0;

	// When a wave is cleared, this is how long until the next wave spawns
	UPROPERTY(Category = "Spawning", meta = (EditCondition = "bSpawnWaves"))
	float DelayBetweenWaves = 0;

	/* How many times the respawn can trigger
	 * Only used if >= 0 else infinte
	 * Will spawn up until the spawned amount reaches this value
	 *
	*/ 
	UPROPERTY(Category = "Spawning", meta = (ClampMin = "0", UIMin = "0"), meta = (EditCondition = "!bSpawnWaves"))
	int RespawnTimes = -1;

	// This will fire when an enemy is killed or removed from the battlefield
	UPROPERTY(Category = "Events")
	FSickleEnemySpawnManagerLostEnemySignature OnEnemyLost;

	// When a new enemy is created
	UPROPERTY(Category = "Events")
	FSickleEnemySpawnManagerSpawnedEnemySignature OnEnemySpawned;

	// When no more spawns available or the spawner is disabled and there is no more enemies
	UPROPERTY(Category = "Events")
	FSickleEnemySpawnManagerFinishedSignature OnFinished;


	// Available positions to spawn at
	UPROPERTY(Category = "Spawn Positions")
	TArray<AActor> SpawnPositions;

	// Internal scene components to spawn at
	UPROPERTY(EditConst, Category = "Spawn Positions")
	TArray<USceneComponent> InternalSpawnPositions;

	UPROPERTY(Category = "Spawn Positions")
	TArray<FSickleEnemySpawnManagerComponentPositionData> LevelSpawnPositions;

	// If set, the spawn manager will collect the current enemies in this area
	// and add them to the current count
	UPROPERTY(EditInstanceOnly, Category = "Spawn Positions")
	ASickleEnemyMovementArea InitialCollectArea;

	UPROPERTY(EditConst, Category = "Spawning")
	FName TeamName;

	TArray<ASickleEnemyMovementArea> AreasWaitingToFinish;
	TArray<USickleEnemySpawningEffect> ActiveSpawnEffects;

	int TotalSpawnAmount = 0;
	int TeamMemberCount = 0;
	int CurrentWaveCount = 0;

	bool bForceSpawnUntilMaxReached = false;
	bool bSpawnManagerIsAttachedToMovingOwner = false;

	UPROPERTY(EditConst, Category = "Spawn Positions", Transient)
	TArray<USceneComponent> CurrentSpawnLocations;

	private bool bCanSpawnMembers = true;
	private TArray<FName> CanSpawnMembersBlocker;
	private bool bHasBeenInitialized = false;
	
	float CurrentSpawnCooldown = 0;
	int PendingSpawnAmount = 0;
	int InitialPendingSpawnAmount = 0;
	int RespawnPoolRemaining = -1;

	TArray<TSubclassOf<ASickleEnemy>> PendingWaveEnemies;
	bool bWantToFinish = false;
	bool bIsFinished = false;
	bool bHasTriggeredFinish = false;
	FVector LastPositionInitialization;
	float LastValidationTime = 0;
	int LevelSpawningIndex = -1;

	UFUNCTION(BlueprintPure)
	int GetRespawnTimesCount()
	{
		return RespawnTimes;
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(EnemyType.IsValid())
			TeamName = FName("Team_" + Owner.GetName() + "_" + EnemyType.Get().GetName());
		else
			TeamName = NAME_None;
    }

	
	FString GetDebugInfo(bool bExtendedEnemyInfo)const
	{
		FString DebugText = "Manager: " + Owner.GetName();
		if(Owner.GetOwner() != nullptr)
			DebugText += "(" + Owner.GetOwner().GetName() + ")";

		const bool SpawningMembers = CanSpawnMembers();
		if(bIsFinished)
		{
			DebugText += " (Finished)";
		}
		else if(SpawningMembers)
		{
			DebugText +=  "(Active)";
		}
		else
		{
			DebugText += "(Disabled)";
			for(int i = 0; i < CanSpawnMembersBlocker.Num(); ++i)
			{
				DebugText += "\n * " + CanSpawnMembersBlocker[i];
			}	
		}

		DebugText += "\n";	
		if(bWantToFinish)
		{
			DebugText += "Will finish when spawning is complete" + "\n";
		}

		if(TeamMemberCount > 0 || SpawningMembers)
		{
			FVector MyPostion = GetOwner().GetActorLocation();
			MyPostion.Z += 100.f;
			
			DebugText += "Enemies controlled: " + TeamMemberCount + " / " + MaxAmount + "\n";
			if(bExtendedEnemyInfo)
			{
				auto AiTeam = HazeAIBlueprintHelper::GetTeam(TeamName);
				if(AiTeam != nullptr)
				{
					for(auto Member : AiTeam.Members)
					{
						DebugText += " * " + Member.GetName() + "\n";
						System::DrawDebugLine(MyPostion, Member.GetActorLocation());
					}
				}
			}

			if(bSpawnWaves)
				DebugText += "Current Wave: " + CurrentWaveCount + "\n";
			else if(RespawnPoolRemaining != 0)
				DebugText += "Respawns remaining: " + RespawnPoolRemaining + "\n";

			const int AmountToSpawn = PendingSpawnAmount + InitialPendingSpawnAmount;
			if(AmountToSpawn > 0)
			{
				DebugText += "PendingSpawnAmount: " + AmountToSpawn + "\n";
				DebugText += "Respawn Cooldown: " + CurrentSpawnCooldown;	
			}
		}

		return DebugText;
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		
		if(SpawnArea == nullptr)
		{
			auto OwningEnemy = Cast<ASickleEnemy>(Owner);
			if(OwningEnemy != nullptr)
			{
				SpawnArea = OwningEnemy.AreaToMoveIn;
			}
		}

		if(SpawnArea != nullptr)
		{
			if(InitialCollectArea != nullptr && !InitialCollectArea.bStartEnabled)
			{
				InitialCollectArea.OnCombatActivated.AddUFunction(this, n"InitializeSystem");
			}
			else
			{
				// We need to wait 1 frame for the sickle system to run its 'BeginPlay' and setup everything
				System::SetTimer(this, n"InitializeSystem", KINDA_SMALL_NUMBER, false);	
			}

			if(bStartDisabled)
			{
				DisableSpawning();
			}

			auto OwnerToAdd = Cast<AHazeActor>(Owner);
			if(OwnerToAdd != nullptr)
			{
				SpawnArea.DebugSpawnManagers.Add(OwnerToAdd);
			}	
		}
		else
		{
			FString DebugText = "The Spawnmanager on ";
			DebugText += GetOwner();
			DebugText += " dont have a valid 'SpawnArea' setup";
			devEnsure(false, DebugText);
			DisableSpawning();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		bCanSpawnMembers = false;
		if(SpawnArea != nullptr)
		{
			auto OwnerToRemove = Cast<AHazeActor>(GetOwner());
			if(OwnerToRemove != nullptr)
				SpawnArea.DebugSpawnManagers.Remove(OwnerToRemove);
		}
	}

	UFUNCTION()
	void EnableSpawning(UObject Instigator = nullptr)
	{
		if(GetWorld().HasControl())
		{
			FName InstigatorName = NAME_None;
			if(Instigator != nullptr)
				InstigatorName = Instigator.GetName();
			NetEnableSpawning(InstigatorName);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetEnableSpawning(FName Instigator)
	{
		if(Instigator == NAME_None)
			bCanSpawnMembers = true;
		else
			CanSpawnMembersBlocker.RemoveSwap(Instigator);
	}

	UFUNCTION()
	void DisableSpawning(UObject Instigator = nullptr)
	{
		if(GetWorld().HasControl())
		{
			FName InstigatorName = NAME_None;
			if(Instigator != nullptr)
				InstigatorName = Instigator.GetName();
			NetDisableSpawning(InstigatorName);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetDisableSpawning(FName Instigator)
	{
		if(Instigator == NAME_None)
			bCanSpawnMembers = false;
		else
			CanSpawnMembersBlocker.AddUnique(Instigator);
	}

	UFUNCTION()
	void EnableFinish()
	{
		if(GetWorld().HasControl())
		{
			bWantToFinish = true;
		}
	}

	// This will enable the spawning pool, or reset the wave back to start
	UFUNCTION()
	void ResetSpawnCount()
	{
		if(GetWorld().HasControl())
		{
			if(bIsFinished || bWantToFinish)
			{
				// We cant finish a spawner who will finish
				return;
			}

			CurrentSpawnCooldown = InitialSpawnDelay;
			if(!bSpawnWaves)
				PendingSpawnAmount += FMath::Max(MaxAmount - TeamMemberCount - PendingSpawnAmount - InitialPendingSpawnAmount, 0);
			else
				CurrentWaveCount = 0;
					
			if(RespawnTimes >= 0)
				RespawnPoolRemaining = RespawnTimes;
		}
	}

	UFUNCTION()
	void ForceSpawnAllPossibleEnemies()
	{
		if(!EnemyType.IsValid())
			return;

		if(bSpawnWaves)
			return;

		bForceSpawnUntilMaxReached = true;
	}

	//  Will destroy all active enemies this manager has spawned @bInstant; destroy without effects
	UFUNCTION()
	void ForceKillAllEnemies(bool bInstant = false)
	{
		// Since the spawning is beeing done from control, we also need to kill from control
		if(GetWorld().HasControl())
		{
			NetForceKillAllEnemies(bInstant);
		}
	}

	UFUNCTION(NetFunction)
	private void NetForceKillAllEnemies(bool bInstant)
	{
		auto Team = HazeAIBlueprintHelper::GetTeam(TeamName);
		if(Team == nullptr)
			return;

		if(Team.Members.Num() == 0)
			return;

		TSet<AHazeActor> Members = Team.Members;
		for(AHazeActor Member : Members)
		{
			auto Enemy = Cast<ASickleEnemy>(Member);
			if(Enemy == nullptr)
				continue;

			Enemy.ManuallyKillEnemy(bInstant);
			Enemy.SetCapabilityActionState(n"AudioSickleEnemySpawn", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void InitializeSystem()
	{
		if(bSpawnWaves && EnemyWaves.Num() == 0)
			return;

		if(!bSpawnWaves && !EnemyType.IsValid())
			return;

		bHasBeenInitialized = true;

		if(InitialCollectArea != nullptr)
		{
			for(ASickleEnemy Enemy : InitialCollectArea.SickleEnemiesControlled)
			{
				if(Enemy == nullptr)
					continue;

				if(!Enemy.IsA(EnemyType))
					continue;

				AddToTeam(Enemy);
			}
		}

		InitializeInitalSpawning();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateSpawnEffects(DeltaTime);

		// We have completed this spawner
		if(bIsFinished)
		{
			if(!bHasTriggeredFinish)
			{
				bHasTriggeredFinish = true;

				OnFinished.Broadcast(Cast<AHazeActor>(Owner));
				for(auto Area : AreasWaitingToFinish)
				{
					Area.OnSpawnManagerComplete();
				}
			}

			return;
		}
		
		// Rare cases can bring the enemies out of world. They then need to be killed
		if(Time::GetGameTimeSince(LastValidationTime) > 1.f)
		{
			ValidatedOutOfWorld();
			LastValidationTime = Time::GetGameTimeSeconds();
		}

		if(GetWorld().HasControl())
		{
			if(!bIsFinished)
			{
				if(GetWorld().HasControl())
				{
					if(CanSpawnMembers() && bHasBeenInitialized && TeamName != NAME_None)
					{
						if(InitialPendingSpawnAmount <= 0)
							CurrentSpawnCooldown = FMath::Max(CurrentSpawnCooldown - DeltaTime, 0.f);

						if(CurrentSpawnCooldown <= 0 
							|| InitialPendingSpawnAmount > 0
							|| bForceSpawnUntilMaxReached)
						{
							if(bSpawnWaves)
							{
								UpdateWaveSpawning();
							}
							else
							{
								UpdateAmountSpawning();
							}
						}
					}
				}
			}

			// Update the finish amount
			if(bWantToFinish)
			{
				if(CanFinish())
					NetFinish();
			}
		}
	}

	bool CanFinish() const
	{
		if(!bHasBeenInitialized)
			return false;
		
		if(TeamMemberCount > 0)
			return false;

		if(PendingSpawnAmount > 0)
			return false;

		if(InitialPendingSpawnAmount > 0)
			return false;

		if(!CanSpawnMembers())
			return true;

		if(bSpawnWaves)
		{
			if(CurrentWaveCount < EnemyWaves.Num())
				return false;
		}
		else 
		{
			if(RespawnPoolRemaining > 0)
				return false;
		}

		return true;
	}

	void ValidatedOutOfWorld()
	{
		USickleEnemySpawnManagerTeam KineticTeam = Cast<USickleEnemySpawnManagerTeam>(HazeAIBlueprintHelper::GetTeam(TeamName));
		if(KineticTeam != nullptr && KineticTeam.Members.Num() > 0)
		{		
			//FVector MyLocation = Owner.GetActorLocation();
			auto CurrentMembers = KineticTeam.Members;
			for(auto TeamMember : CurrentMembers)
			{
				ASickleEnemy TeamMemberEnemy = Cast<ASickleEnemy>(TeamMember);
				if(TeamMemberEnemy.bIsSpawning)
					continue;

				if(!TeamMemberEnemy.bLockToArea)
					continue;

				if(TeamMemberEnemy.bInvalidSpawn)
				{
					NetSafetyDestroyActor(TeamMember);
				}
				else
				{
					auto AiComp = USickleEnemyComponentBase::Get(TeamMember);
					if(AiComp != nullptr)
					{
						AiComp.ValidatePositionInCombatArea();
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSafetyDestroyActor(AHazeActor Enemy)
	{
		if(Enemy == nullptr)
			return;

		USickleEnemySpawnManagerTeam KineticTeam = Cast<USickleEnemySpawnManagerTeam>(HazeAIBlueprintHelper::GetTeam(TeamName));
		if(KineticTeam == nullptr)
			return;
		
		if(KineticTeam.Members.Num() == 0)
			return;

		if(!KineticTeam.Members.Contains(Enemy))
			return;

		Enemy.DestroyActor();
	}

	private void InitializeInitalSpawning()
	{
		InitializeDefaultSpawnLocations();
		if(GetWorld().HasControl())
		{
			CurrentSpawnCooldown = InitialSpawnDelay;
			if(!bSpawnWaves)
			{
				if(InitialSpawnAmount < 0)
					InitialPendingSpawnAmount = MaxAmount;
				else if(InitialSpawnAmount > 0)
					InitialPendingSpawnAmount = InitialSpawnAmount;

				PendingSpawnAmount = FMath::Max(MaxAmount - InitialPendingSpawnAmount, 0);
			}
			else
			{
				CurrentWaveCount = 0;
			}
					
			if(RespawnTimes >= 0)
				RespawnPoolRemaining = RespawnTimes;
		}
	}

	private bool CanSpawnMembers()const
	{
		if(!bCanSpawnMembers)
			return false;
		else if(CanSpawnMembersBlocker.Num() > 0)
			return false;
		else
			return true;
	}

	private void UpdateWaveSpawning()
	{
		if(PendingWaveEnemies.Num() > 0)
		{
			SpawnEnemies(PendingWaveEnemies[0]);	
			PendingWaveEnemies.RemoveAt(0);
			if(PendingWaveEnemies.Num() > 0)
				CurrentSpawnCooldown = DelayBetweenSpawns;
			else
				CurrentSpawnCooldown = DelayBetweenWaves;

			return;
		}

		if(TeamMemberCount > 0)
			return; // Wait for the wave to clear

		if(CurrentWaveCount >= EnemyWaves.Num())
			return; // No more spawning

		const FSickleEnemySpawnManagerWave& WaveToSpawn = EnemyWaves[CurrentWaveCount];
		PendingWaveEnemies.Append(WaveToSpawn.EnemyTypesToSpawn);
		CurrentWaveCount++;
		UpdateWaveSpawning(); // Recursion
	}

	private void UpdateAmountSpawning()
	{
		if(InitialPendingSpawnAmount > 0)
		{
			InitialPendingSpawnAmount--;
			SpawnEnemies(EnemyType);
			return;
		}

		if(PendingSpawnAmount > 0)
		{
			SpawnEnemies(EnemyType);
			PendingSpawnAmount--;
			CurrentSpawnCooldown = DelayBetweenSpawns;
		}

		if(TeamMemberCount >= MaxAmount)
		{
			bForceSpawnUntilMaxReached = false;
			return;
		}
		else if(bForceSpawnUntilMaxReached)
		{
			PendingSpawnAmount++;
			return;
		}

		if(PendingSpawnAmount > 0)
			return;

		if(RespawnPoolRemaining == 0)
			return; // No more spawning

		if(bWantToFinish && RespawnPoolRemaining < 0)
			return; // No more spawning

		if(TeamMemberCount <= MinAmont)
		{	
			if(RespawnPoolRemaining > 0)
				RespawnPoolRemaining--;

			int AmountToAdd = 0;
			if(RespawnPoolRemaining > 0)
			{
				AmountToAdd = FMath::Min(MaxAmount - TeamMemberCount, RespawnPoolRemaining);
				RespawnPoolRemaining -= AmountToAdd;
			}
			else
			{
				AmountToAdd = MaxAmount - TeamMemberCount;
			}

			PendingSpawnAmount = AmountToAdd;
			CurrentSpawnCooldown = DelayBetweenSpawns;
		}
	}

	private void SpawnEnemies(TSubclassOf<ASickleEnemy> Type)
	{
		// Always make sure we have spawn positions
		if(CurrentSpawnLocations.Num() == 0 || bSpawnManagerIsAttachedToMovingOwner)
			SetLevelSpawnPositionIndex(LevelSpawningIndex);


	#if EDITOR
		// TArray<USceneComponent> DebugTestedSpawnLocations = CurrentSpawnLocations;
		// TArray<FHazeTraceParams> TestedTraces;
		// TArray<FHazeHitResult> TestedResults;
		FString DebugText = "";
	#endif

		FVector SpawnLocation = GetOwner().RootComponent.GetWorldLocation();

		// Make sure we go through all the spawn locations before resetting them
		USceneComponent SpawnLocationComponent = nullptr;
		do
		{
			const int SpawnIndex = FMath::RandRange(0, CurrentSpawnLocations.Num() - 1);
			SpawnLocationComponent = CurrentSpawnLocations[SpawnIndex];
			CurrentSpawnLocations.RemoveAt(SpawnIndex);	

			if(SpawnLocationComponent != nullptr)
			{
				// The the world location from the component
				SpawnLocation = SpawnLocationComponent.GetWorldLocation();

				if(bSpawnManagerIsAttachedToMovingOwner)
				{
					auto AttachParent = Cast<AHazeCharacter>(GetOwner().GetAttachParentActor());
					ensure(AttachParent != nullptr && AttachParent.IsA(ASickleEnemy::StaticClass()), "Spawn manager not attached to correct actor class");

					USickleEnemyComponentBase AiComponentTemplate = USickleEnemyComponentBase::Get(AttachParent);

					// First, make sure the spawnpoint is inside the area
					if(SpawnArea != nullptr)
					{
						SpawnArea.BrushComponent.GetClosestPointOnCollision(SpawnLocation, SpawnLocation);
					}

					// Then, make sure we can reach the area by tracing there
					FHazeTraceParams TraceParams;
					TraceParams.InitWithMovementComponent(AiComponentTemplate);

					// Remove the things we should not collide with
					TraceParams.IgnoreActor(GetOwner());

					// Since we can be at a collision edge, test closer to the middle of the area
					TraceParams.From = AttachParent.GetActorCenterLocation();
					FVector DirToSpawnCenter = (SpawnArea.BrushComponent.GetWorldLocation() - TraceParams.From).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
					if(!DirToSpawnCenter.IsNearlyZero())
					{
						SpawnLocation += DirToSpawnCenter * AttachParent.GetCollisionSize().X;
					}
					
					TraceParams.To = SpawnLocation;

				// #if EDITOR
				// // 	TraceParams.DebugDrawTime = 5.f; // If zero it will be shown for one frame.
				// 	TestedTraces.Add(TraceParams);
				// #endif

					FHazeHitResult Hit;
					if (TraceParams.Trace(Hit))
					{
						bool bIsWalkable = IsHitSurfaceWalkableDefault(
							Hit.FHitResult, 
							AiComponentTemplate.WalkableAngle, 
							FVector::UpVector);

						if(bIsWalkable)
							SpawnLocation = Hit.ImpactPoint;
						else
							SpawnLocationComponent = nullptr;
					}

					if(SpawnLocationComponent != nullptr)
					{
						TraceParams.SetToLineTrace();
						TraceParams.From = SpawnLocation + FVector::UpVector;
						TraceParams.To = TraceParams.From - (FVector::UpVector * AttachParent.GetCollisionSize().Y * 2);
						if (TraceParams.Trace(Hit))
						{
							if(IsHitSurfaceWalkableDefault(
								Hit.FHitResult, 
								AiComponentTemplate.WalkableAngle, 
								FVector::UpVector))
							{
								SpawnLocation = Hit.ImpactPoint + FVector::UpVector;
							}
							else
							{
								SpawnLocationComponent = nullptr;		
							}
						}
						else
						{
							SpawnLocationComponent = nullptr;
						}
					}

					// #if EDITOR
					// 	TestedResults.Add(Hit);
					// #endif
				}
			}
	
		} while(SpawnLocationComponent == nullptr && CurrentSpawnLocations.Num() > 0);
	
#if EDITOR
	if(SpawnLocationComponent == nullptr)
	{
		DebugText = "SpawnManagerRoot";
	}
	else
	{
		if(SpawnLocationComponent.GetOwner() == GetOwner())
			DebugText = SpawnLocationComponent.GetName();
		else
			DebugText = SpawnLocationComponent.GetOwner().GetName();
	}
#endif

	#if EDITOR	
		if(SpawnArea != nullptr)
		{
			FVector WantedSpawnLocation = SpawnLocation;
			WantedSpawnLocation += (SpawnArea.GetActorLocation() - WantedSpawnLocation).GetSafeNormal() * 200.f;
			float SpawnDistanceValue = SpawnArea.BrushComponent.GetClosestPointOnCollision(WantedSpawnLocation, SpawnLocation);
			if(SpawnDistanceValue < 0)
			{
				System::DrawDebugSphere(WantedSpawnLocation, 500.f, Duration = 10.f, LineColor = FLinearColor::Red);
				devEnsure(false, "SpawnArea: " + SpawnArea.GetName() + " does not have a valid collision profile!");
			}
			else if(WantedSpawnLocation.DistSquared(SpawnLocation) > FMath::Square(10))
			{
				if(SpawnDistanceValue > 0)
				{
					System::DrawDebugSphere(WantedSpawnLocation, 500.f, Duration = 10.f, LineColor = FLinearColor::Red);
					devEnsure(false, "Spawn location: " + DebugText + " is not inside a valid spawn area: " + SpawnArea.GetName());
				}
				else
				{
					devEnsure(false, "SpawnArea: " + SpawnArea.GetName() + " is not a valid convex shape!");
				}
			}
		}
	#endif

		NetSpawnActor(Type, SpawnLocation, FMath::RandRange(0.f, 360.f));
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSpawnActor(TSubclassOf<ASickleEnemy> Type, FVector SpawnLocation, float RandomDirection)
	{
		
		FRotator SpawnRotation = FRotator(0.f, RandomDirection, 0.f);
		ASickleEnemy NewEnemy = Cast<ASickleEnemy>(SpawnActor(Type, 
			SpawnLocation, 
			SpawnRotation,
			bDeferredSpawn = true,
			Level = Owner.GetLevel()));
			
		if(NewEnemy != nullptr)
		{
			NewEnemy.MakeNetworked(this, TotalSpawnAmount);
			AddToTeam(NewEnemy);
			NewEnemy.FinishSpawningActor();
			TotalSpawnAmount++;
			if(NewEnemy.SpawnEffectClass.IsValid())
			{
				auto Effect = Cast<USickleEnemySpawningEffect>(NewObject(NewEnemy, NewEnemy.SpawnEffectClass));
				Effect.Owner = NewEnemy;
				Effect.OnSpawned();
				NewEnemy.bIsSpawning = true;
				ActiveSpawnEffects.Add(Effect);
			}

			NewEnemy.SetCapabilityActionState(n"AudioSickleEnemySpawn", EHazeActionState::ActiveForOneFrame);
			OnEnemySpawned.Broadcast(NewEnemy);
		}
	}

	private void UpdateSpawnEffects(float DeltaTime)
	{
		for(int i = ActiveSpawnEffects.Num() - 1; i >= 0; --i)
		{
			auto Effect = ActiveSpawnEffects[i];
			if(Effect.IsComplete())
			{
				if(Effect.Owner != nullptr)
				{
					Effect.Owner.bIsSpawning = false;
					Effect.OnSpawnedComplete();
				}
							
				ActiveSpawnEffects.RemoveAtSwap(i);
			}	
			else
			{
				Effect.Tick(DeltaTime);
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetFinish()
	{
		bIsFinished = true;
	}

	void AddToTeam(ASickleEnemy Enemy)
	{
		auto Team = Cast<USickleEnemySpawnManagerTeam>(Enemy.JoinTeam(TeamName, USickleEnemySpawnManagerTeam::StaticClass()));
		Team.SpawnManager = this;
		Enemy.TeamName = TeamName;
		TeamMemberCount++;
	
		if(Enemy.AreaToMoveIn == nullptr)
		{
			Enemy.AreaToMoveIn = SpawnArea;
			SpawnArea.EnemyAdded(Enemy);
		}
		else if(Enemy.AreaToMoveIn != SpawnArea)
		{
			FString DebugText = "The enemy ";
			DebugText += Enemy;
			DebugText += " has movearea ";
			DebugText += Enemy.AreaToMoveIn;
			DebugText += " but the spawn manager on";
			DebugText += GetOwner();
			DebugText += " wants it to belong to ";
			DebugText += SpawnArea;
			devEnsure(false,DebugText);
		}	
	}

	UFUNCTION()
	void ActivateLevelSpawnPositions(FName LevelName)
	{
		if(!devEnsure(LevelName != NAME_None, "ActivateLevelSpawnPositions need a level name"))
			return;

		for(int i = 0; i < LevelSpawnPositions.Num(); ++i)
		{
			if(LevelSpawnPositions[i].Level == LevelName)
			{
				LevelSpawningIndex = i;
				return;
			}
		}

		devEnsure(false, "ActivateLevelSpawnPositions could not find " + LevelName);
	}

	private void SetLevelSpawnPositionIndex(int Index)
	{
		if(Index < 0)
			InitializeDefaultSpawnLocations();
		else
			InitializeLevelSpawnLocations(Index);
	}

	private void InitializeDefaultSpawnLocations()
	{
		CurrentSpawnLocations.Reset();

		for(auto SpawnActor : SpawnPositions)
		{
			if(SpawnActor == nullptr)
				continue;

			CurrentSpawnLocations.Add(SpawnActor.RootComponent);
		}

		for(auto SpawnLocation : InternalSpawnPositions)
		{
			if(SpawnLocation == nullptr)
				continue;

			CurrentSpawnLocations.Add(SpawnLocation);
		}

		if(CurrentSpawnLocations.Num() == 0)
		{
			// No valid location so we add the actor as the valid location
			CurrentSpawnLocations.Add(GetOwner().RootComponent);
		}
	}

	private void InitializeLevelSpawnLocations(int Index)
	{
		CurrentSpawnLocations.Reset();

		auto LevelSpawnContainer = LevelSpawnPositions[Index];
		for(auto SpawnLocation : LevelSpawnContainer.SpawnPositions)
		{
			if(SpawnLocation == nullptr)
				continue;

			CurrentSpawnLocations.Add(SpawnLocation.RootComponent);
		}

		if(CurrentSpawnLocations.Num() == 0)
		{
			// No valid location so we add the actor as the valid location
			CurrentSpawnLocations.Add(GetOwner().RootComponent);
		}
	}
}


class USickleEnemySpawnManagerTeam : UHazeAITeam
{
	USickleEnemySpawnManagerComponent SpawnManager;

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		auto Enemy = Cast<ASickleEnemy>(Member);
		if(SpawnManager != nullptr)
		{
			SpawnManager.TeamMemberCount--;
			SpawnManager.OnEnemyLost.Broadcast(SpawnManager.TeamMemberCount);
		}
	}
}


