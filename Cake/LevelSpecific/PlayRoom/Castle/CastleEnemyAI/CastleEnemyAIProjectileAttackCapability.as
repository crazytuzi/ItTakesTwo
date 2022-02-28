import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.CastleEnemyAIAttackCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;

class UCastleEnemyAIProjectileAttackCapability : UCastleEnemyAIAttackCapabilityBase
{
	default PreAttackTrackTime = 0.25f;
	default AttackPoint = 0.5f;
	default AttackMaxDistance = 99999999.f;
	default AttackCooldownMin = 3.f;
	default AttackCooldownMax = 6.f;

	// Minimum damage dealt to the player
	UPROPERTY()
	float MinPlayerDamageDealt = 10.f;

	// Maximum damage dealt to the player
	UPROPERTY()
	float MaxPlayerDamageDealt = 10.f;

	// Type of projectile to spawn when firing
	UPROPERTY()
	TSubclassOf<ACastleEnemyProjectile> ProjectileType;

	// Visualization component to use before firing
	UPROPERTY()
	UStaticMeshComponent Visualization;
	UPROPERTY()
	UMaterialInstanceDynamic VisualizationMaterialInstance;

	UPROPERTY()
	FHazeTimeLike VisualizationFadeOutTimeLike;
	default VisualizationFadeOutTimeLike.Duration = 0.25f;

	int SpawnProjectileCounter = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		UCastleEnemyAIAttackCapabilityBase::Setup(Params);

		Visualization = CreateProjectileVisualization();
		if (Visualization != nullptr)
			Visualization.SetHiddenInGame(true);

		VisualizationFadeOutTimeLike.BindUpdate(this, n"OnFadeOutUpdate");
		VisualizationFadeOutTimeLike.BindFinished(this, n"OnFadeOutFinished");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UCastleEnemyAIAttackCapabilityBase::OnActivated(ActivationParams);

		if (Visualization != nullptr)
		{
			Visualization.SetHiddenInGame(false);
			Enemy.SetCapabilityActionState(n"AudioStartAttack", EHazeActionState::Active);
			UpdateProjectileVisualization(Visualization, GetChargePercentage(), IsStillTracking());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UCastleEnemyAIAttackCapabilityBase::OnDeactivated(DeactivationParams);

		if (Visualization != nullptr)
			VisualizationFadeOutTimeLike.PlayFromStart();
		// 	Visualization.SetHiddenInGame(true);
	}

	UFUNCTION()
	void OnFadeOutUpdate(float Value)
	{
		if (VisualizationMaterialInstance == nullptr)
			return;

		VisualizationMaterialInstance.SetScalarParameterValue(n"Time", Value);
	}

	UFUNCTION()
	void OnFadeOutFinished()
	{
		if (Visualization != nullptr)
			Visualization.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Super::OnRemoved();
		if (Visualization != nullptr)
			Visualization.DestroyComponent(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UCastleEnemyAIAttackCapabilityBase::TickActive(DeltaTime);
		
		if (Visualization != nullptr)
		{
			if (CVar_HideCastleAttackDecals.GetInt() == 0)
				UpdateProjectileVisualization(Visualization, GetChargePercentage(), IsStillTracking());
			else
				Visualization.SetHiddenInGame(true);
		}
	}

	void ExecuteAttack(FAttackExecuteEvent Event) override
	{
		if (Event.bCanceled)
			return;

		UCastleEnemyAIAttackCapabilityBase::ExecuteAttack(Event);
		//System::DrawDebugLine(Enemy.ActorCenterLocation, AttackLocation, FLinearColor::Red, Duration=1.f, Thickness=5.f);

		// 	Visualization.SetHiddenInGame(true);

		if (!ProjectileType.IsValid())
			return;

		FVector SourceLocation = Enemy.ActorCenterLocation;

		ACastleEnemyProjectile Projectile = Cast<ACastleEnemyProjectile>(SpawnActor(ProjectileType.Get(), SourceLocation));
		if (Projectile == nullptr)
			return;

		Projectile.MakeNetworked(this, SpawnProjectileCounter++);
		Projectile.Target = Event.AttackingPlayer;
		Projectile.TargetLocation = Event.AttackingPlayer.ActorLocation;
		Projectile.FireDirection = Event.AttackDirection;
		Projectile.ProjectileDamageRoll = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);
		Projectile.ProjectileTargeted();
		Projectile.ProjectileFired();

		Enemy.SetCapabilityAttributeObject(n"AudioProjectileFired", Projectile);		
	}

	UFUNCTION(BlueprintEvent)
	UStaticMeshComponent CreateProjectileVisualization()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void UpdateProjectileVisualization(UStaticMeshComponent Component, float PercentCharged, bool bTracking)
	{
	}
};