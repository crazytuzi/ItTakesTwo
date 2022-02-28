import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.CastleEnemyBreakableWall;

class UCastleEnemyBreakableDeathCapability : UHazeCapability
{
    ACastleEnemyBreakableWall Enemy;
    float CurrentTime = -1.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemyBreakableWall>(Owner);
        Enemy.OnKilled.AddUFunction(this, n"OnKilled");
    }

    UFUNCTION()
    void OnKilled(ACastleEnemy DamagedEnemy, bool bKilledByDamage)
    {
		FVector DeathDirection = Enemy.PreviousDamageEvent.DamageDirection.GetSafeNormal2D();
		if (DeathDirection.IsNearlyZero())
			DeathDirection = Enemy.ActorForwardVector * -1.f;
		if (!Enemy.KillDirection.IsNearlyZero())
			DeathDirection = Enemy.KillDirection;

        Enemy.bDelayDeath = true;
		Enemy.BreakBreakable(DeathDirection);
        CurrentTime = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (CurrentTime >= 0.f)
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
		Owner.SetActorEnableCollision(false);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CurrentTime += DeltaTime;
        if (CurrentTime >= Enemy.DespawnTimerAfterDeath)
            Enemy.FinalizeDeath();
    }
};