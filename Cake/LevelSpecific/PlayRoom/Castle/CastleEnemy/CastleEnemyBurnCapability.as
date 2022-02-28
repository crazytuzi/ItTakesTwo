import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyBurnCapability : UHazeCapability
{	
    ACastleEnemy Enemy;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (Enemy.GetStatusMagnitude(ECastleEnemyStatusType::Burn) >= 1.f && DeactiveDuration > 1.f && !Enemy.bKilled)
            return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::DontActivate;			
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DeactivateLocal; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		FCastleEnemyDamageEvent Damage;
		Damage.DamageSource = Game::May;
		Damage.DamageDealt = Enemy.BurningDPS;
		Damage.DamageLocation = Enemy.ActorLocation + FVector(0, 0, 90);
		Damage.DamageDirection = FVector::UpVector;
		Damage.DamageType = ECastleEnemyDamageType::Burn;
		Damage.DamageSpeed = 500.f;

		Enemy.TakeDamage(Damage);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
	}
}