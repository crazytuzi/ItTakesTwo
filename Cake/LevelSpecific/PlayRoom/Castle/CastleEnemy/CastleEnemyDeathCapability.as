import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyDeathCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 1;

    UPROPERTY()
    float DieTime = 0.5f;

    UPROPERTY()
    float SinkTime = 1.5f;

    ACastleEnemy Enemy;
    float CurrentTime = -1.f;

	UHazeBaseMovementComponent MoveComp;
	bool bDeathFinalized = false;
	bool bDeathTriggered = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnKilled.AddUFunction(this, n"OnKilled");

		MoveComp = UHazeBaseMovementComponent::Get(Enemy);
    }

    UFUNCTION()
    void OnKilled(ACastleEnemy DamagedEnemy, bool bKilledByDamage)
    {
		if (Enemy.bDead)
			return;
        Enemy.bDelayDeath = true;
        CurrentTime = 0.f;

        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
        Owner.BlockCapabilities(n"CastleEnemyAttack", this);
        Owner.BlockCapabilities(n"CastleEnemyAbility", this);
        Owner.BlockCapabilities(n"CastleEnemyAI", this);
		Owner.SetActorEnableCollision(false);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (CurrentTime >= 0.f && !bDeathTriggered)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bDeathTriggered = true;

		if (Enemy.EnemyDeathEffect != nullptr)
			Niagara::SpawnSystemAtLocation(Enemy.EnemyDeathEffect, Enemy.ActorLocation, Enemy.ActorRotation);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		if (!bDeathFinalized)
		{
            Enemy.FinalizeDeath();
			bDeathFinalized = true;
			CurrentTime = -1.f;
		}
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyDeath");
			Movement.FlagToMoveWithDownImpact();

			FVector DeathDirection = Enemy.PreviousDamageEvent.DamageDirection.GetSafeNormal2D();
			if (DeathDirection.IsNearlyZero())
				DeathDirection = Enemy.ActorForwardVector * -1.f;

			Movement.ApplyDeltaWithCustomVelocity(FVector(0.f), DeathDirection);
			MoveComp.Move(Movement);

			Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyDeath", NAME_None);
		}

        CurrentTime += DeltaTime;

		if (CurrentTime >= DieTime)
		{
			float SinkPct = (CurrentTime - DieTime) / (SinkTime - DieTime);
			FVector Offset = FVector(0.f, 0.f, 100.f * SinkPct);
			Enemy.MeshOffsetComponent.OffsetLocationWithTime(Enemy.ActorLocation - Offset, 0.f);
		}

        if (CurrentTime >= DieTime + SinkTime)
		{
            Enemy.FinalizeDeath();
			bDeathFinalized = true;
		}
    }
};