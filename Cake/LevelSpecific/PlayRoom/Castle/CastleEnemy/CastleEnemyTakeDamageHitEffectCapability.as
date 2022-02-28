import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Peanuts.DamageFlash.DamageFlashStatics;

class UCastleEnemyTakeDamageHitEffectCapability : UHazeCapability
{	
	UPROPERTY()
	UNiagaraSystem EffectType;
	UPROPERTY()
	UNiagaraSystem EffectType_Burn;
	UPROPERTY()
	float ScaleMin = 0.2f;
	UPROPERTY()
	float ScaleMax = 0.8f;

    ACastleEnemy Enemy;
	UNiagaraComponent BurnComp;
	bool bShouldBeActive = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
        Enemy.OnKilled.AddUFunction(this, n"OnKilled");

		if (EffectType_Burn != nullptr)
		{
			BurnComp = Niagara::SpawnSystemAttached(
				EffectType_Burn,
				Enemy.RootComponent, NAME_None,
				FVector(0, 0, 125), FRotator(), EAttachLocation::KeepRelativeOffset,
				bAutoDestroy = false, bAutoActivate = false);
		}
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
		if (DamagedEnemy.bKilled)
			return;

		if (Event.DamageType == ECastleEnemyDamageType::Burn)
			BurnComp.Activate();
		else
			DisplayHitMarker(EffectType);
		bShouldBeActive = true;
    }

    UFUNCTION()
    void OnKilled(ACastleEnemy KilledEnemy, bool bKilledByDamage)
    {
		BurnComp.SetHiddenInGame(true);
		BurnComp.Deactivate();
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bShouldBeActive && !Enemy.bKilled)
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

	void DisplayHitMarker(UNiagaraSystem UseEffect)
	{
		if (UseEffect == nullptr)
			return;

		UNiagaraComponent Effect = Niagara::SpawnSystemAtLocation(UseEffect, Enemy.ActorLocation + FVector(0, 0, 125), FRotator::ZeroRotator);
		Effect.SetNiagaraVariableFloat("User.Scale", FMath::RandRange(ScaleMin, ScaleMax));
	}
}