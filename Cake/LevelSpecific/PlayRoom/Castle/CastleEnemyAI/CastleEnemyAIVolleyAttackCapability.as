import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.CastleEnemyAIAttackCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;

class UCastleEnemyAIVolleyAttackCapability : UCastleEnemyAIAttackCapabilityBase
{
	default PreAttackTrackTime = 0.25f;
	default AttackPoint = 0.5f;
	default AttackMaxDistance = 99999.f;
	default AttackCooldownMin = 3.f;
	default AttackCooldownMax = 6.f;
	default bTrackInstantly = true;

	// Amount of projectiles in volley
	UPROPERTY()
	int ProjectilesInVolley = 3;

	// Angle difference that projectiles are spawned with
	UPROPERTY()
	float SpawnStepAngle = 10.f;

	// Angle different that projectiles are launched in an arc with
	UPROPERTY()
	float SpreadStepAngle = 10.f;

	// Spawn offset towards the target
	UPROPERTY()
	float SpawnDistanceTowardsTarget = 100.f;

	// Minimum damage dealt to the player
	UPROPERTY()
	float MinPlayerDamageDealt = 10.f;

	// Maximum damage dealt to the player
	UPROPERTY()
	float MaxPlayerDamageDealt = 10.f;

	// Type of projectile to spawn when firing
	UPROPERTY()
	TSubclassOf<ACastleEnemyProjectile> ProjectileType;

	// After this many volleys, pause and try to switch target
	UPROPERTY()
	int PauseAfterVolleys = 3;

	// Pause time after an amount of volleys
	UPROPERTY()
	float PauseTime = 1.5f;

	// Projectiles that are currently being fired
	TArray<ACastleEnemyProjectile> Projectiles;
	TArray<FAttackExecuteEvent> ExecuteEvents;

	int SpawnProjectileCounter = 0;
	int VolleyCounter = 0;
	bool bIsPaused = false;

	AHazePlayerCharacter PreviousTarget;
	AHazePlayerCharacter LastBarrageTarget;

	bool CanStartAttack() override
	{
		if (VolleyCounter >= PauseAfterVolleys)
			return false;
		return Super::CanStartAttack();
	}

	int GetTargetPriority(AHazePlayerCharacter Player) override
	{
		if (Player != LastBarrageTarget)
			return 2;
		return 1;
	}

	bool HasAttackControl() override
	{
		if (AttackingPlayer != nullptr)
			return AttackingPlayer.HasControl();
		else
			return HasControl();
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Super::PreTick(DeltaTime);

		if (VolleyCounter >= PauseAfterVolleys)
		{
			if (DeactiveDuration > PauseTime)
			{
				VolleyCounter = 0;
				LastBarrageTarget = PreviousTarget;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UCastleEnemyAIAttackCapabilityBase::OnActivated(ActivationParams);

		FVector SourceLocation = Enemy.ActorCenterLocation;
		for (int Proj = 0; Proj < ProjectilesInVolley; ++Proj)
		{
			ACastleEnemyProjectile Projectile = Cast<ACastleEnemyProjectile>(SpawnActor(ProjectileType.Get(), SourceLocation));
			Projectile.MakeNetworked(this, SpawnProjectileCounter++);
			Projectiles.Add(Projectile);
		}

		UpdateProjectileTargets(AttackingPlayer, AttackDirection);

		if (ExecuteEvents.Num() != 0)
		{
			FireProjectiles(ExecuteEvents[0]);
			ExecuteEvents.RemoveAt(0);
		}

		VolleyCounter += 1;
		PreviousTarget = AttackingPlayer;

		Enemy.SetCapabilityActionState(n"AudioStartedChargingProjectile", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Super::OnRemoved();

		// Fizzle any projectiles that were never fired at all
		for (auto Projectile : Projectiles)
			Projectile.ProjectileFizzled();
	}

	void UpdateProjectileTargets(AHazePlayerCharacter ProjectileTarget, FVector ProjectileDirection)
	{
		float SpawnAngle = 0.f;
		SpawnAngle -= FMath::FloorToFloat(ProjectilesInVolley / 2.f) * SpawnStepAngle;
		if (ProjectilesInVolley % 2 == 0)
			SpawnAngle -= SpawnStepAngle * 0.5f;

		float FireAngle = 0.f;
		FireAngle -= FMath::FloorToFloat(ProjectilesInVolley / 2.f) * SpreadStepAngle;
		if (ProjectilesInVolley % 2 == 0)
			FireAngle -= SpreadStepAngle * 0.5f;

		for (ACastleEnemyProjectile Projectile : Projectiles)
		{
			Projectile.Target = ProjectileTarget;
			Projectile.TargetLocation = ProjectileTarget.ActorLocation;

			FQuat ProjRotation = FQuat(FVector::UpVector, FMath::DegreesToRadians(FireAngle));
			Projectile.FireDirection = ProjRotation.RotateVector(ProjectileDirection);

			FQuat SpawnRotation = FQuat(FVector::UpVector, FMath::DegreesToRadians(SpawnAngle));

			FVector ProjectileSpawnOffset;
			ProjectileSpawnOffset = SpawnRotation.RotateVector(ProjectileDirection * SpawnDistanceTowardsTarget);
			Projectile.SetActorLocation(Enemy.ActorCenterLocation + ProjectileSpawnOffset);

			Projectile.ProjectileDamageRoll = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);
			Projectile.ProjectileTargeted();

			FireAngle += SpreadStepAngle;
			SpawnAngle += SpawnStepAngle;
		}
	}

	void OnUpdateAttackDirection() override
	{
		UpdateProjectileTargets(AttackingPlayer, AttackDirection);
	}

	void FireProjectiles(FAttackExecuteEvent Event)
	{
		if (!ProjectileType.IsValid())
			return;

		UpdateProjectileTargets(Event.AttackingPlayer, Event.AttackDirection);

		if (Event.bCanceled)
		{
			for (ACastleEnemyProjectile Projectile : Projectiles)
				Projectile.ProjectileFizzled();
			Projectiles.Empty();
		}
		else
		{
			for (ACastleEnemyProjectile Projectile : Projectiles)
			{
				Projectile.ProjectileFired();				
			}
			Enemy.SetCapabilityActionState(n"AudioProjectileFired", EHazeActionState::ActiveForOneFrame);
			Projectiles.Empty();
		}
	}

	void ExecuteAttack(FAttackExecuteEvent Event) override
	{
		UCastleEnemyAIAttackCapabilityBase::ExecuteAttack(Event);

		if (Projectiles.Num() != 0)
			FireProjectiles(Event);
		else
			ExecuteEvents.Add(Event);
	}
};