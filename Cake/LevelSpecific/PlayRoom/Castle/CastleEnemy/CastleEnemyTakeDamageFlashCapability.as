import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Peanuts.DamageFlash.DamageFlashStatics;

class UCastleEnemyTakeDamageFlashCapability : UHazeCapability
{	
	UPROPERTY()
	float FlashDuration = 0.12f;
	UPROPERTY()
	FLinearColor FlashColor = FLinearColor(0.5f, 0.5f, 0.5f, 0.2f);
    ACastleEnemy Enemy;
	bool bShouldBeActive = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
        FlashActor(DamagedEnemy, FlashDuration, FlashColor);
		bShouldBeActive = true;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bShouldBeActive)
            return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;			
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (!bShouldBeActive)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		return EHazeNetworkDeactivation::DontDeactivate; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bShouldBeActive = false;
	}
}