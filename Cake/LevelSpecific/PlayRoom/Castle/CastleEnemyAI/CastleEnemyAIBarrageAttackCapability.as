import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.CastleEnemyAIAttackCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;

class UCastleEnemyAIBarrageAttackCapability : UCastleEnemyAIAttackCapabilityBase
{
	default PreAttackTrackTime = 0.25f;
	default AttackPoint = 0.5f;
	default AttackMaxDistance = 2000.f;
	default AttackCooldownMin = 3.f;
	default AttackCooldownMax = 6.f;

	// Amount of projectiles fired in this barrage
	UPROPERTY()
	int ProjectilesInBarrage = 3;

	// Time between projectile firing from the barrage
	UPROPERTY()
	float TimeBetweenProjectiles = 0.5f;

	// Minimum damage dealt to the player
	UPROPERTY()
	float MinPlayerDamageDealt = 10.f;

	// Maximum damage dealt to the player
	UPROPERTY()
	float MaxPlayerDamageDealt = 10.f;

	// Type of projectile to spawn when firing
	UPROPERTY()
	TSubclassOf<ACastleEnemyProjectile> ProjectileType;

	int ProjectilesRemaining = 0;
	int SpawnProjectileCounter = 0;
	float BarrageTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UCastleEnemyAIAttackCapabilityBase::OnActivated(ActivationParams);
		ProjectilesRemaining = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UCastleEnemyAIAttackCapabilityBase::TickActive(DeltaTime);

		if (ProjectilesRemaining > 0 && HasControl())
		{
			BarrageTimer += DeltaTime;
			if (BarrageTimer >= TimeBetweenProjectiles)
			{
				BarrageTimer -= TimeBetweenProjectiles;

				FAttackExecuteEvent Event;
				Event.AttackLocation = AttackLocation;
				Event.AttackDirection = AttackDirection;
				NetFireProjectile(Event);
			}
		}
	}

	bool IsAttackDone() const
	{
		if (!UCastleEnemyAIAttackCapabilityBase::IsAttackDone())
			return false;
		if (ProjectilesRemaining > 0)
			return false;
		return true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetFireProjectile(FAttackExecuteEvent Event)
	{
		FireProjectile(Event);
	}

	void FireProjectile(FAttackExecuteEvent Event)
	{
		ProjectilesRemaining -= 1;

		if (!ProjectileType.IsValid())
			return;

		FVector SourceLocation = Enemy.ActorCenterLocation;

		ACastleEnemyProjectile Projectile = Cast<ACastleEnemyProjectile>(SpawnActor(ProjectileType.Get(), SourceLocation));
		Projectile.MakeNetworked(this, SpawnProjectileCounter++);
		Projectile.Target = AttackingPlayer;
		Projectile.TargetLocation = AttackingPlayer.ActorLocation;
		Projectile.FireDirection = Event.AttackDirection;
		Projectile.ProjectileDamageRoll = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);
		Projectile.ProjectileTargeted();
		Projectile.ProjectileFired();
	}

	void ExecuteAttack(FAttackExecuteEvent Event) override
	{
		if (Event.bCanceled)
			return;

		UCastleEnemyAIAttackCapabilityBase::ExecuteAttack(Event);

		ProjectilesRemaining = ProjectilesInBarrage;
		BarrageTimer = 0.f;

		FireProjectile(Event);
	}
};