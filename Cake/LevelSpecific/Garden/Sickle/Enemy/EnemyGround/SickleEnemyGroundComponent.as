
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Peanuts.Animation.Features.Garden.FeatureEnemyGardenTree;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;

class USickleEnemyGroundComponent : USickleEnemyComponentBase
{
	default SickleImpact.KnockBackAmount = FVector(110, 0, 0);
	default SickleImpact.KnockBackHorizontalMovementTime = 0.3f;
	default StayAtReachedTargetTime = FHazeMinMax(0.f, 3.f);
	default bDepenetrateOutOfOtherMovementComponents = false;
	default WhipHit.KnockBackAmount = FVector(0, 0, 500.f);

	default ControlSideDefaultCollisionSolver = n"AICharacterGroundedDetectionSolverOnlyLineTrace";
	default RemoteSideDefaultCollisionSolver = n"AICharacterGroundedDetectionSolverOnlyLineTrace";

	UPROPERTY(Category = "Movement")
	float KeepDistanceToOtherEnemies = 0;

	UPROPERTY(Category = "Animations")
	UFeatureEnemyGardenTree AnimationFeature;

	UPROPERTY(Category = "Combat|Shield")
	bool bHasShield = false;

	UPROPERTY(Category = "Combat|Shield", meta = (EditCondition = "bHasShield"))
	bool bCanDropShield = false;

	UPROPERTY(Category = "Combat|Shield", meta = (EditCondition = "bHasShield && bCanDropShield"))
	float TimeToDropShield = 0.72f;

	UPROPERTY(Category = "Combat|Shield", meta = (EditCondition = "bHasShield && !bCanDropShield"))
	float TimeToLoseVineImpact = 3.0f;

	// How long this actor will be stunned after loosing shield
	UPROPERTY(Category = "Combat|Shield", meta = (EditCondition = "bHasShield && bCanDropShield"))
	float ShieldLostStunnedDuration = 1.5f;

	/* How far from the player the enemy will stand when dash attacking with the shield
	 * Will only be activated if inside min and max range
	*/
	UPROPERTY(Category = "Combat", EditDefaultsOnly, meta = (EditCondition = "bHasShield"))
	float ShieldDashAttackMinDistance = 500.f;

	UPROPERTY(Category = "Combat|Shield", EditDefaultsOnly, meta = (EditCondition = "bHasShield && bCanDropShield"))
	USkeletalMesh NakedType;

	UPROPERTY(Category = "Effects", EditDefaultsOnly, meta = (EditCondition = "bHasShield && bCanDropShield"))
	UNiagaraSystem ShieldDestroyedEffect;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	FVector ImpactOffset = FVector(150.f, 0.f, 0.f);

	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem GroundSlamEffect;

	UPROPERTY(Category = "Combat")
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY(Category = "Combat")
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category = "Combat")
	int DamageAmount = 1;

	// If used, the spawnmanager will be activated when the shielder has releases the vine impact
	UPROPERTY(Category = "Combat")
	AHazeActor ExternalSpawnManager;

	private USickleEnemySpawnManagerComponent SpawnManager;
	private int SpawnedAmount = 0;
	private TPerPlayer<bool> bSpawningIsEnabled;
	private int InvalidPositionCounter = 0;
	FVector LastValidPosition;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();
		auto EnemyOwner = Cast<ASickleEnemy>(Owner);
		Setup(EnemyOwner.CapsuleComponent);

		bSpawningIsEnabled[0] = bSpawningIsEnabled[1] = false;
		LastValidPosition = GetOwner().GetActorLocation();

		if(ExternalSpawnManager != nullptr)
			SpawnManager = USickleEnemySpawnManagerComponent::Get(ExternalSpawnManager);
		else
			SpawnManager = USickleEnemySpawnManagerComponent::Get(Owner);
		
		if(SpawnManager != nullptr)
		{
			// Since the spawnmanager is attached to the owner, we need to do extra evaluations
			SpawnManager.bSpawnManagerIsAttachedToMovingOwner = true;
			SpawnManager.OnEnemySpawned.AddUFunction(this, n"OnChildSpawned");;
		}
	}

	UFUNCTION(BlueprintOverride)
	float GetStepAmount(float WantedAmount) const
	{
		return 80.f;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnChildSpawned(ASickleEnemy Enemy)
	{
		SpawnedAmount++;
		if(SpawnedAmount >= SpawnManager.MaxAmount)
		{
			for(auto Player : Game::GetPlayers())
			{
				if(Player.HasControl())
				{
					FHazeDelegateCrumbParams Data;
					Data.AddNumber(n"Player", Player.Player);
					UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetSpawningDisabled"), Data);
				}
			}
		}
	}

	void EnableSpawning()
	{
		if(SpawnManager == nullptr)
			return;

		for(auto Player : Game::GetPlayers())
		{
			if(Player.HasControl())
			{
				FHazeDelegateCrumbParams Data;
				Data.AddNumber(n"Player", Player.Player);
				UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetSpawningEnabled"), Data);
			}
		}
	}

	void BlockSpawning(UObject Instigator)
	{
		if(SpawnManager != nullptr && Instigator != nullptr)
		{
			SpawnManager.DisableSpawning(Instigator);
		}
	}

	void UnblockSpawning(UObject Instigator)
	{
		if(SpawnManager != nullptr && Instigator != nullptr)
		{
			SpawnManager.EnableSpawning(Instigator);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_SetSpawningEnabled(const FHazeDelegateCrumbData& CrumbData)
	{
		if(SpawnManager == nullptr)
			return;
	
		bSpawningIsEnabled[CrumbData.GetNumber(n"Player")] = true;

		if(!bSpawningIsEnabled[0] || !bSpawningIsEnabled[1])
			return;

		SpawnManager.ResetSpawnCount();
		SpawnManager.EnableSpawning();
		SpawnedAmount = SpawnManager.TeamMemberCount;
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_SetSpawningDisabled(const FHazeDelegateCrumbData& CrumbData)
	{
		if(SpawnManager == nullptr)
			return;

		const bool bDisableSpawning = bSpawningIsEnabled[0] && bSpawningIsEnabled[1];
		bSpawningIsEnabled[CrumbData.GetNumber(n"Player")] = false;
		
		if(bDisableSpawning)
			SpawnManager.DisableSpawning();
	}

	void ValidatePositionInCombatArea() override
	{
		const FVector CurrentLocation = Owner.GetActorLocation();
		const float DistSq = CurrentLocation.DistSquared(LastValidPosition);
		if(DistSq < FMath::Square(50.f))
			return;

		FVector FoundLocation;
		auto EnemyOwner = Cast<ASickleEnemy>(Owner);
		if(!EnemyOwner.IsInsideMoveArea(FoundLocation))
		{
			EnemyOwner.CleanupCurrentMovementTrail();
			EnemyOwner.SetActorLocation(LastValidPosition);
			InvalidPositionCounter++;
		}
		else
		{
			if(IsGrounded() && IsHitSurfaceWalkableDefault(
				GetImpacts().DownImpact, 
				WalkableAngle, 
				FVector::UpVector))
			{
				InvalidPositionCounter = 0;
				LastValidPosition = EnemyOwner.GetActorLocation();
			}
			else if(DistSq > FMath::Square(1000.f))
			{
				InvalidPositionCounter++;
			}
			else if(FMath::Abs(CurrentLocation.Z - LastValidPosition.Z) > 300.f)
			{
				InvalidPositionCounter++;
			}
		}

		// This will destroy the enemy
		EnemyOwner.bInvalidSpawn = InvalidPositionCounter >= 120;
	}
}

#if EDITOR
class USickleEnemyGroundComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USickleEnemyGroundComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto Comp = Cast<USickleEnemyGroundComponent>(Component);
        if (Comp == nullptr)
            return;

		if(Comp.KeepDistanceToOtherEnemies <= 0)
			return;
	
		DrawCircle(Component.Owner.GetActorLocation(), Comp.KeepDistanceToOtherEnemies, FLinearColor::Green, 10.0f);
    }   
}

#endif // EDITOR