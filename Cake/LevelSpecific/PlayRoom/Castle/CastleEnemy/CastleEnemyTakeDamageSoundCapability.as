import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

UCLASS(Abstract)
class UCastleEnemyTakeDamageSoundCapability : UHazeCapability
{	
    ACastleEnemy Enemy;
	bool bShouldBeActive = false;

	UPROPERTY()
	UAkAudioEvent AudioEvent;

	UHazeAkComponent HazeAkComp;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		HazeAkComp = UHazeAkComponent::Get(Owner, n"HazeAkComponent");
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
		if (AudioEvent != nullptr)
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
		HazeAkComp.HazePostEvent(AudioEvent);
		bShouldBeActive = false;
	}
}