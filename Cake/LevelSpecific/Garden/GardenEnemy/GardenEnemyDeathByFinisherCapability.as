import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UGardenEnemyDeathByFinisherCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::LastMovement;

    UPROPERTY()
    float Duration = 0.5f;

    ACastleEnemy Enemy;
    float CurrentTime = -1.f;

	UHazeBaseMovementComponent MoveComp;

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
        Enemy.bDelayDeath = true;
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
        Owner.BlockCapabilities(n"Movement", this);
		Owner.BlockCapabilities(n"CastleEnemyKnockback", this);
        Owner.BlockCapabilities(n"CastleEnemyAttack", this);
        Owner.BlockCapabilities(n"CastleEnemyAbility", this);
		Owner.BlockCapabilities(n"CastleEnemyAI", this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"Movement", this);
		Owner.UnblockCapabilities(n"CastleEnemyKnockback", this);
        Owner.UnblockCapabilities(n"CastleEnemyAttack", this);
        Owner.UnblockCapabilities(n"CastleEnemyAbility", this);
		Owner.UnblockCapabilities(n"CastleEnemyAI", this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (IsActioning(n"FinalizeDeath"))
            Enemy.FinalizeDeath();
    }
}