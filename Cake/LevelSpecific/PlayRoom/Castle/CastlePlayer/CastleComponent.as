import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleDamageNumbers;
import Peanuts.Outlines.Outlines;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.UI.CastlePlayerHUDWidget;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastlePlayerAnimationData;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.UI.CastlePlayerHealthBarWidget;
import Vino.PlayerHealth.PlayerHealthComponent;

event void FOnPlayerDamagedCastleEnemy(ACastleEnemy Enemy, FCastleEnemyDamageEvent DamageEvent);
event void FOnPlayerCastleDamageTaken(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent);

const FConsoleVariable CVar_HideCastleAttackDecals("Haze.HideCastleAttackDecals", 0);

class UCastleComponent : UActorComponent
{
    AHazePlayerCharacter OwningPlayer;

	UHazeSmoothSyncFloatComponent SyncUltimateCharge;

    UPROPERTY()
    TSubclassOf<UCastleDamageNumberWidget> DamageNumberWidget;

    UPROPERTY()
	float CriticalStrikeChance = 0.25f;
	UPROPERTY()
	float CriticalStrikeDamage = 1.5f;
    UPROPERTY()
    float UltimateChargeMax = 1000.f;
    UPROPERTY(NotEditable)
    float UltimateCharge = 0.f;    
	UPROPERTY()
	float UltimateDecayRate = 0.f;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback_SmallHit;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback_HeavyHit;

	UPROPERTY()
	UNiagaraSystem HitEffect;

    UPROPERTY(Meta = (BPCannotCallEvent))
    FOnPlayerDamagedCastleEnemy OnDamagedEnemy;

    UPROPERTY(Meta = (BPCannotCallEvent))
    FOnPlayerCastleDamageTaken OnDamageTaken;

	TArray<ACastleEnemy> AllEnemies;

	bool bHiddenFromEnemies = false;

	UPROPERTY(Category = "Combo")
	int ComboCurrent = 0;
	UPROPERTY(Category = "Combo")
	bool bComboCanAttack = true;
	UPROPERTY(Category = "Combo")
	bool bComboCanReset = false;

	UPROPERTY(Category = "Major Ability")
	float MajorCooldownCurrent = 0.f;	

	UPROPERTY()
	TSubclassOf<UCastlePlayerHUDWidget> HUDClass;
	UCastlePlayerHUDWidget HUD;

	UPROPERTY()
	TSubclassOf<UCastlePlayerHealthBarWidget> HealthBarClass;
	UCastlePlayerHealthBarWidget HealthBar;

	UPROPERTY()
	UCastleAnimationBruteDataAsset BruteAnimationData;
	UPROPERTY()
	UCastleAnimationMageDataAsset MageAnimationData;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> AudioDamageEffectClass;

	UPlayerDamageEffect AudioDamageEffect;

	bool bIsBlinking = false;
	bool bUsingUltimate = false;
	FVector BlinkStartLocation;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);

		SyncUltimateCharge = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"SyncUltimateCharge");
		SyncUltimateCharge.OnValueChanged.AddUFunction(this, n"OnUltimateChargeSyncChanged");

		GetOrCreateHUD();

		if (HealthBarClass.IsValid())
		{
			HealthBar = Cast<UCastlePlayerHealthBarWidget>(OwningPlayer.AddWidget(HealthBarClass));
			HealthBar.SetWidgetShowInFullscreen(true);
			HealthBar.SetWidgetPersistent(true);
			HealthBar.AttachWidgetToComponent(OwningPlayer.Mesh);
			HealthBar.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 176.f));
		}

		AudioDamageEffect = Cast<UPlayerDamageEffect>(NewObject(this, AudioDamageEffectClass.Get()));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (HUD != nullptr)
			Widget::RemoveFullscreenWidget(HUD);
		if (HealthBar != nullptr)
			OwningPlayer.RemoveWidget(HealthBar);
	}

	UCastlePlayerHUDWidget GetOrCreateHUD()
	{
		if (!HUDClass.IsValid())
			return nullptr;

		if (OwningPlayer.IsCody())
		{
			auto MayCastleComp = UCastleComponent::Get(OwningPlayer.OtherPlayer);
			return MayCastleComp.GetOrCreateHUD();
		}

		if (HUD == nullptr)
		{
			HUD = Cast<UCastlePlayerHUDWidget>(Widget::AddFullscreenWidget(HUDClass));
			HUD.SetWidgetPersistent(true);
		}

		return HUD;	
	}

    UFUNCTION()
    void TakeDamage(FCastlePlayerDamageEvent DamageEvent)
    {
        if (HasControl())
        {
            if (!CanPlayerBeDamaged(OwningPlayer))
                return;

			OwningPlayer.DamagePlayerHealth(DamageEvent.DamageDealt / 100.f,
				TSubclassOf<UPlayerDamageEffect>(UDummyPlayerDamageEffect::StaticClass()));
            NetPlayerDamageEffect(DamageEvent);
        }
    }

    UFUNCTION(NetFunction, NotBlueprintCallable)
    void NetPlayerDamageEffect(FCastlePlayerDamageEvent DamageEvent)
    {
        // Show the damage number
        if (DamageEvent.DamageDealt > 0.f && DamageNumberWidget.IsValid())
            ShowCastleDamageNumber(OwningPlayer, DamageNumberWidget, DamageEvent.DamageDealt, DamageEvent.DamageLocation, DamageEvent.DamageDirection, DamageEvent.DamageSpeed, false, true, OwningPlayer.Player);

        // Create the damage effect
        UCastleDamageEffect Effect;
        if (DamageEvent.DamageEffect.IsValid())
            Effect = Cast<UCastleDamageEffect>(NewObject(this, DamageEvent.DamageEffect.Get()));
        else
            Effect = Cast<UCastleDamageEffect>(NewObject(this, UDummyCastleDamageEffect::StaticClass()));

        Effect.DamageEvent = DamageEvent;

        // Inform the lives system
        OnDamageTaken.Broadcast(OwningPlayer, DamageEvent);

		HealthComp.PlayDamageEffect(Effect);

		if(AudioDamageEffect != nullptr)
		{
			if (OwningPlayer.IsMay() && AudioDamageEffect.MayDamageAudioEvent != nullptr)
				OwningPlayer.PlayerHazeAkComp.HazePostEvent(AudioDamageEffect.MayDamageAudioEvent);
				
			else if (OwningPlayer.IsCody() && AudioDamageEffect.CodyDamageAudioEvent != nullptr)
				OwningPlayer.PlayerHazeAkComp.HazePostEvent(AudioDamageEffect.CodyDamageAudioEvent);

		if (OwningPlayer.IsMay() && AudioDamageEffect.MayDamageVoEvent != nullptr)
				PlayFoghornEffort(AudioDamageEffect.MayDamageVoEvent, OwningPlayer);
				
			else if (OwningPlayer.IsCody() && AudioDamageEffect.CodyDamageVoEvent != nullptr)
				PlayFoghornEffort(AudioDamageEffect.CodyDamageVoEvent, OwningPlayer);
		}		
    }

    UFUNCTION()
    void PlayerDamagedEnemy(ACastleEnemy Enemy, FCastleEnemyDamageEvent DamageEvent)
    {                
		if (!bUsingUltimate)
			AddUltimateCharge(DamageEvent.DamageDealt * Enemy.HitUltimateChargeMultiplier);
		//DisplayHitMarker(Enemy);
        OnDamagedEnemy.Broadcast(Enemy, DamageEvent);
    }

    void AddUltimateCharge(int Amount)
    {
		if (HasControl())
		{
			UltimateCharge += Amount;
			UltimateCharge = FMath::Clamp(UltimateCharge, 0.f, UltimateChargeMax);
			SyncUltimateCharge.Value = UltimateCharge;
		}
    }

	UFUNCTION(BlueprintPure)
	float GetUltimatePercentage() property
	{
		return UltimateCharge / UltimateChargeMax;
	}

	void DisplayHitMarker(ACastleEnemy Enemy)
	{
		if (HitEffect == nullptr)
			return;

		UNiagaraComponent Effect = Niagara::SpawnSystemAtLocation(HitEffect, Enemy.ActorLocation + FVector(0, 0, 125), FRotator::ZeroRotator);

		Effect.SetNiagaraVariableFloat("User.Scale", FMath::RandRange(0.2f, 0.8f));
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        DecayUltimateCharge(DeltaTime);

		if (HealthBar != nullptr)
		{
			HealthBar.bIsDead = HealthComp.bIsDead;
			HealthBar.CurrentHealth = HealthComp.CurrentHealth - HealthComp.RecentlyRegeneratedHealth;
			HealthBar.RecentHealth = HealthComp.CurrentHealth + HealthComp.RecentlyLostHealth - HealthComp.RecentlyRegeneratedHealth;
			HealthBar.Update();
		}
    }

    UFUNCTION()
	private void OnUltimateChargeSyncChanged()
	{
		if (!HasControl())
			UltimateCharge = SyncUltimateCharge.Value;
	}

	void DecayUltimateCharge(float DeltaTime)
	{
		if (HasControl())
		{
			UltimateCharge = FMath::Clamp(UltimateCharge - UltimateDecayRate * DeltaTime, 0.f, UltimateChargeMax);
			SyncUltimateCharge.Value = UltimateCharge;
		}
	}

	void UpdateCombo(int Combo)
	{
		ComboCurrent = Combo;
	}

	bool IsAttackCritical(float OverrideCritChance = 0.f)
	{
		float Chance = CriticalStrikeChance;
		if (OverrideCritChance > 0.f)
			Chance = OverrideCritChance;

		float CritCheck = FMath::RandRange(0.f, 1.f);
		if (CritCheck <= Chance)
			return true;
		
		return false;
	}

	/*
		Find the best target enemy within a cone and distance in the direction provided
		TODO: Score the results based off of distance and angle
	*/
	ACastleEnemy FindTargetEnemy(FRotator Rotation, float MaxDistance = 1000.f, float ConeAngle = 80.f)
    {
        TArray<ACastleEnemy> NearbyEnemies = GetCastleEnemiesInCone(Owner.GetActorLocation(), Rotation, MaxDistance, ConeAngle);

        ACastleEnemy ValidEnemy;
        float ValidEnemyAngle = 360;
        float ValidEnemyDistance = MaxDistance;

        if (NearbyEnemies.Contains(ValidEnemy))
            return ValidEnemy;

        for (ACastleEnemy NearbyEnemy : NearbyEnemies)
        {
			if (NearbyEnemy.bUnhittable)
				continue;

			if (NearbyEnemy.bInvulnerable)
				continue;

			if (!IsHittableByAttack(OwningPlayer, NearbyEnemy, NearbyEnemy.ActorLocation))
				continue;

            FVector PlayerToEnemy = NearbyEnemy.ActorLocation - Owner.ActorLocation;
			PlayerToEnemy.Z = 0.f;
            float NearbyEnemyDistance = PlayerToEnemy.Size();
            PlayerToEnemy.Normalize();


            float PlayerToEnemyDot = PlayerToEnemy.DotProduct(Owner.ActorForwardVector);
            float NearbyEnemyAngle = FMath::RadiansToDegrees(FMath::Acos(PlayerToEnemyDot));  

            if (NearbyEnemyDistance < ValidEnemyDistance)
            {
                ValidEnemy = NearbyEnemy;
                ValidEnemyAngle = NearbyEnemyAngle;
                ValidEnemyDistance = NearbyEnemyDistance;
            }
        }

		return ValidEnemy;
    }
}


struct FCastleHitEffect
{
    UPROPERTY()
    ACastleEnemy Enemy;
    UPROPERTY()
    FCastleEnemyDamageEvent Event;
    UPROPERTY()
    float TimeSinceHit = 0.f;
}

struct FCastleHitTimer
{
	UPROPERTY()
	ACastleEnemy CastleEnemy;

	UPROPERTY()
	float Duration;
}


UFUNCTION()
void DamageCastleEnemy(AHazePlayerCharacter Player, ACastleEnemy Enemy, FCastleEnemyDamageEvent DamageEvent)
{
    if (Enemy.TakeDamage(DamageEvent))
    	UCastleComponent::Get(Player).PlayerDamagedEnemy(Enemy, DamageEvent);
}

UFUNCTION()
void TriggerCastlePlayerTakeDamage(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
{
	if (UCastleComponent::Get(Player) != nullptr)
    	UCastleComponent::Get(Player).TakeDamage(DamageEvent);
}

bool IsPlayerHiddenFromEnemies(AHazePlayerCharacter Player)
{
	if (UCastleComponent::Get(Player) == nullptr)
		return false;

    return UCastleComponent::Get(Player).bHiddenFromEnemies;
}

void SetPlayerHiddenFromEnemies(AHazePlayerCharacter Player, bool bHiddenFromEnemies)
{  
	UCastleComponent::Get(Player).bHiddenFromEnemies = bHiddenFromEnemies;
}
