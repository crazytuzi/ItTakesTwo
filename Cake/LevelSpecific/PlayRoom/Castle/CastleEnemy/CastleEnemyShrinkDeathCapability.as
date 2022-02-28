
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyShrinkDeathCapability : UHazeCapability
{
    UPROPERTY()
    float Duration = 0.5f;

    ACastleEnemy Enemy;
    float CurrentTime = -1.f;

	UHazeBaseMovementComponent MoveComp;
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
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        CurrentTime += DeltaTime;
        if (CurrentTime >= Duration)
            Enemy.FinalizeDeath();

        MoveComp.SetControlledComponentScale(FVector(FMath::Clamp(1.f - (CurrentTime / Duration), 0.2f, 1.f)));
    }
};