import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.PlayerHealth.PlayerGenericEffect;

import Vino.PlayerHealth.PlayerDamageEffect;
import Vino.PlayerHealth.PlayerDeathEffect;
import Peanuts.DamageFlash.DamageFlashStatics;

delegate void FOnPlayerDied(AHazePlayerCharacter Player);

enum EGodMode
{
	Mortal,
	Jesus,
	God,
};

class UDummyPlayerDamageEffect : UPlayerDamageEffect
{
	default bPlayUniversalDamageEffect = false;
	
	void Activate()
	{
		Super::Activate();
		FinishEffect();
	}
};

class UDummyPlayerDeathEffect : UPlayerDeathEffect
{
	void Activate()
	{
		Super::Activate();
		FinishEffect();
	}
};

struct FPlayerDiedLocation
{
	bool bValid = false;
	EHazeGroundedState GroundedState;
	UPrimitiveComponent RelativeToComponent;
	FVector Location;
	FRotator Rotation;

	void Fill(AHazePlayerCharacter Player)
	{
		UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Player);
		if (MoveComp != nullptr)
		{
			bValid = true;
			GroundedState = MoveComp.GroundedState;
			Rotation = Player.ActorRotation;

			if (!MoveComp.GetCurrentMoveWithComponent(RelativeToComponent, Location))
				Location = Player.ActorLocation;
		}
	}

	void Clear()
	{
		bValid = false;
		RelativeToComponent = nullptr;
	}
};

class UPlayerHealthComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> HealthDisplayWidget;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DefaultDeathEffect = UDummyPlayerDeathEffect::StaticClass();

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DefaultDamageEffect = UDummyPlayerDamageEffect::StaticClass();

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DefaultDeathVolumeEffect;

	UPROPERTY()
	TSubclassOf<UPlayerUniversalDamageEffect> UniversalDamageEffect;

	private TArray<UObject> InvulnerabilityInstigators;
	private TArray<float> InvulnerabilityTimers;
	private	float InIFrameTime = 0;
	private TArray<UPlayerDamageEffect> ActiveDamageEffects;
	private TArray<UPlayerDeathEffect> ActiveDeathEffects;

	EGodMode GodMode = EGodMode::Mortal;

	bool bIsDead = false;
	bool bDeathBlocked = false;
	bool bForceAlive = false;
	float GameTimeAtLastDeath = -1.f;

	FPlayerDiedLocation DiedAtLocation;

	// Current health the player has at this time
	float CurrentHealth = 1.f;

	// Amount of health that has been lost recently
	float RecentlyLostHealth = 0.f;
	float GameTimeAtMostRecentDamage = -1.f;
	bool bStartedDamageCharge = false;

	// Amount of health that has been healed recently
	float RecentlyHealedHealth = 0.f;
	float GameTimeAtMostRecentHeal = -1.f;
	bool bStartedHealCharge = false;

	// Amount of health that has been regenerated recently
	//  Regeneration is different from heal in how it is displayed
	float RecentlyRegeneratedHealth = 0.f;
	float TotalRegeneratingHealth = 0.f;

	AHazePlayerCharacter Player;
	UPlayerHealthSettings HealthSettings;
	FOnPlayerDied OnPlayerDied;
	
	const float RecentDelayAfterDamage = 0.5f;
	const float RecentDamageDecayRate = 0.5f;

	const float RecentDelayAfterHeal = 0.5f;
	const float RecentHealDecayRate = 0.5f;

	const float RegenerateDuration = 1.f;

	private bool bFlashInvulnerability = false;
	private FLinearColor FlashColor;
	private float FlashPulseDuration = 0.f;
	private float FlashPulseInterval = 0.f;
	private float FlashTimer = 0.f;
	private float NextFlash = 0.f;

	bool bVisibilityBlocked = false;

	int ResetCounter = 0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float GameTime = Time::GetGameTimeSeconds();

		// Decay the recently lost health counter
		if (RecentlyLostHealth > 0.f)
		{
			if (GameTime > GameTimeAtMostRecentDamage + RecentDelayAfterDamage)
				bStartedDamageCharge = true;

			if (bStartedDamageCharge)
				RecentlyLostHealth = FMath::Max(0.f, RecentlyLostHealth - DeltaTime * RecentDamageDecayRate);
		}
		else
		{
			bStartedDamageCharge = false;
		}

		// Decay the recently healed health counter
		if (RecentlyHealedHealth > 0.f)
		{
			if (GameTime > GameTimeAtMostRecentHeal + RecentDelayAfterHeal)
				bStartedHealCharge = true;
			
			if (bStartedHealCharge)
				RecentlyHealedHealth = FMath::Max(0.f, RecentlyHealedHealth - DeltaTime * RecentHealDecayRate);
		}
		else
		{
			bStartedHealCharge = false;
		}

		// Decay the recently regenerated health counter
		if (RecentlyRegeneratedHealth > 0.f)
		{
			RecentlyRegeneratedHealth = FMath::Max(0.f, RecentlyRegeneratedHealth - (DeltaTime / RegenerateDuration));
		}
		else
		{
			TotalRegeneratingHealth = 0.f;
		}

		// If we are put in a cutscene, all effects should be deactivated
		if (IsBeingForcedAlive())
		{
			DeactivateDeathEffects();
			DeactivateDamageEffects();
		}

		// Update timeouts for any duration invulnerabilities we have
		for (int i = InvulnerabilityTimers.Num() - 1; i >= 0; i--)
		{
			InvulnerabilityTimers[i] -= DeltaTime;
			if (InvulnerabilityTimers[i] <= 0.f)
				InvulnerabilityTimers.RemoveAt(i);
		}

		for (int i = ActiveDamageEffects.Num() - 1; i >= 0; i--)
		{
			auto Effect = ActiveDamageEffects[i];
			Effect.Tick(DeltaTime);

			// Remove damage effects as soon as they are finished
			if (Effect.bFinished)
			{
				if (Effect.bActive)
					Effect.Deactivate();
				ActiveDamageEffects.RemoveAt(i);
			}
		}

		for (int i = ActiveDeathEffects.Num() - 1; i >= 0; i--)
		{
			auto DeathEffect = ActiveDeathEffects[i];

			// Invalid effects can happen if it activates after the respawn triggerd in network
			if(DeathEffect.bStale || (DeathEffect.bFinished && !bIsDead))
			{
				if (DeathEffect.bActive)
					DeathEffect.Deactivate();

				ActiveDeathEffects.RemoveAt(i);
				continue;
			}
			
			DeathEffect.Tick(DeltaTime);
			// Death effects are not removed until the respawn occurs
		}


		if (bFlashInvulnerability)
		{
			if (!HealthSettings.bDisplayHealth || (InvulnerabilityTimers.Num() == 0 && InvulnerabilityInstigators.Num() == 0) || Player.bIsControlledByCutscene)
			{
				bFlashInvulnerability = false;
				if (Player.bIsControlledByCutscene)
					ClearPlayerFlash(Player);
			}
			else
			{
				FlashTimer += DeltaTime;
				if (FlashTimer >= NextFlash)
				{
					FlashPlayer(Player, FlashPulseDuration, FlashColor);
					NextFlash += FlashPulseInterval;
				}
			}
		}
	}

	TSubclassOf<UPlayerDeathEffect> GetDefaultEffect_Death()
	{
		if (HealthSettings.DefaultDeathEffect.IsValid())
			return HealthSettings.DefaultDeathEffect;
		return DefaultDeathEffect;
	}

	TSubclassOf<UPlayerDeathEffect> GetDefaultEffect_DeathVolume()
	{
		if (HealthSettings.DefaultDeathVolumeEffect.IsValid())
			return HealthSettings.DefaultDeathVolumeEffect;
		if (DefaultDeathVolumeEffect.IsValid())
			return DefaultDeathVolumeEffect;
		return GetDefaultEffect_Death();
	}

	TSubclassOf<UPlayerDamageEffect> GetDefaultEffect_Damage()
	{
		if (HealthSettings.DefaultDamageEffect.IsValid())
			return HealthSettings.DefaultDamageEffect;
		return DefaultDamageEffect;
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType Type)
	{
		ResetCounter += 1;
		ResetHealth();
		InvulnerabilityInstigators.Empty();
		InvulnerabilityTimers.Empty();

		for (auto DeathEffect : ActiveDeathEffects)
		{
			if (DeathEffect.bActive)
				DeathEffect.Deactivate();
		}
        ActiveDeathEffects.Empty();

		for (auto DamageEffect : ActiveDamageEffects)
		{
			if (DamageEffect.bActive)
				DamageEffect.Deactivate();
		}
        ActiveDamageEffects.Empty();

		GameTimeAtLastDeath = -1.f;
		DiedAtLocation.Clear();
		OnPlayerDied.Clear();
	}

	void PlayDamageEffect(UPlayerDamageEffect Effect)
	{
		Effect.Player = Player;
		Effect.WorldContext = Player;
		Effect.Activate();

		ActiveDamageEffects.Add(Effect);
	}

	void PlayDamageEffect(TSubclassOf<UPlayerDamageEffect> DamageEffect, bool bCanPlayUniversalEffect = true)
	{
		UPlayerDamageEffect Effect;
		if (DamageEffect.IsValid())
			Effect = Cast<UPlayerDamageEffect>(NewObject(Player, DamageEffect.Get()));
		else
			Effect = Cast<UPlayerDamageEffect>(NewObject(Player, GetDefaultEffect_Damage().Get()));

		PlayDamageEffect(Effect);

		if (Effect.bPlayUniversalDamageEffect && bCanPlayUniversalEffect && UniversalDamageEffect.IsValid())
		{
			auto UniversalEffect = Cast<UPlayerUniversalDamageEffect>(NewObject(Player, UniversalDamageEffect.Get()));
			UniversalEffect.WantedEffectDuration = Effect.UniversalDamageEffectDuration;
			PlayDamageEffect(UniversalEffect);
		}
	}

	void PlayDeathEffect(TSubclassOf<UPlayerDeathEffect> DeathEffect, bool bAsStale)
	{
		UPlayerDeathEffect Effect;
		if (DeathEffect.IsValid())
			Effect = Cast<UPlayerDeathEffect>(NewObject(Player, DeathEffect.Get()));
		else
			Effect = Cast<UPlayerDeathEffect>(NewObject(Player, GetDefaultEffect_Death().Get()));

		Effect.Player = Player;
		Effect.WorldContext = Player;
		Effect.Activate();
		Effect.bStale = bAsStale;
		ActiveDeathEffects.Add(Effect);
	}

	bool DoDeathEffectsSupportRespawnInPlace()
	{
		for (auto Effect : ActiveDeathEffects)
		{
			if (!Effect.bAllowRespawnInPlace)
				return false;
		}
		return true;
	}

	bool AreDeathEffectsFinished()
	{
		for (auto Effect : ActiveDeathEffects)
		{
			if (!Effect.bFinished)
				return false;
		}
		return true;
	}

	void AddInvulnerability(UObject Instigator)
	{
		InvulnerabilityInstigators.AddUnique(Instigator);
	}

	void RemoveInvulnerability(UObject Instigator)
	{
		InvulnerabilityInstigators.Remove(Instigator);
	}

	void AddInvulnerabilityDuration(float Duration)
	{
		InvulnerabilityTimers.Add(Duration);
	}

	void SetIFrameActive()
	{
		// We are safe for 1 frame. Or 2 if this is 60 fps.
		float GameTime = Time::GetGameTimeSeconds();
		InIFrameTime = GameTime + (1.f / 30.f);
	}

	bool CanDie()
	{
		if (GodMode == EGodMode::God)
			return false;
		if (bIsDead)
			return false;
		if (bDeathBlocked)
			return false;
		return true;
	}

	bool InIFrame()const
	{
		float GameTime = Time::GetGameTimeSeconds();
		return GameTime < InIFrameTime;
	}

	bool CanTakeDamage()
	{
		if (InvulnerabilityInstigators.Num() != 0)
			return false;
		if (InvulnerabilityTimers.Num() != 0)
			return false;
		if (GodMode == EGodMode::God)
			return false;
		if (bIsDead)
			return false;
		for (auto DamageEffect : ActiveDamageEffects)
		{
			if (DamageEffect.bInvulnerableDuringEffect)
				return false;
		}
		return true;
	}

	bool WouldDieFromDamage(float Amount)
	{
		if (GodMode == EGodMode::Jesus)
			return false;
		if ((CurrentHealth - Amount) >= KINDA_SMALL_NUMBER)
			return false;
		if (!CanDie())
			return false;

		return true;
	}

	bool Damage(float Amount)
	{
		// Never allow damage to be actually taken in Jesus mode
		//  We are not marked invulnerable in this mode because all other
		//  effects from damage should still happen
		if (GodMode == EGodMode::Jesus)
			return false;

		float PreviousHealth = CurrentHealth;
		CurrentHealth = FMath::Clamp(CurrentHealth - Amount, 0.f, 1.f);

		// If we healed this damage recently, remove the recent heal
		float DamagedHealth = FMath::Min(PreviousHealth, Amount);
		float TakeFromHeal = FMath::Min(DamagedHealth, RecentlyHealedHealth);
		if (TakeFromHeal > 0.f)
			RecentlyHealedHealth -= TakeFromHeal;
		float TakeFromRegeneration = FMath::Min(DamagedHealth - TakeFromHeal, RecentlyRegeneratedHealth);
		if (TakeFromRegeneration > 0.f)
		{
			RecentlyRegeneratedHealth -= TakeFromRegeneration;
			TotalRegeneratingHealth -= TakeFromRegeneration;
		}

		Player.SetCapabilityAttributeValue(n"AudioDamagedHealth", DamagedHealth);

		RecentlyLostHealth += DamagedHealth;
		GameTimeAtMostRecentDamage = Time::GetGameTimeSeconds();

		return FMath::IsNearlyZero(CurrentHealth, KINDA_SMALL_NUMBER);
	}

	void Heal(float Amount)
	{
		float PreviousHealth = CurrentHealth;
		CurrentHealth = FMath::Clamp(CurrentHealth + Amount, 0.f, 1.f);

		// If we took the damage we healed recently, remove the recent damage
		float HealedHealth = FMath::Min(1.f - PreviousHealth, Amount);
		if (HealedHealth > 0.f)
		{
			RecentlyLostHealth = FMath::Max(0.f, RecentlyLostHealth - HealedHealth);
			RecentlyHealedHealth += HealedHealth;
			GameTimeAtMostRecentHeal = Time::GetGameTimeSeconds();
		}
	}

	void Regenerate(float Amount)
	{
		float PreviousHealth = CurrentHealth;
		CurrentHealth = FMath::Clamp(CurrentHealth + Amount, 0.f, 1.f);

		// If we took the damage we healed recently, remove the recent damage
		float RegeneratedHealth = FMath::Min(1.f - PreviousHealth, Amount);
		if (RegeneratedHealth > 0.f)
		{
			RecentlyLostHealth = FMath::Max(0.f, RecentlyLostHealth - RegeneratedHealth);
			RecentlyRegeneratedHealth += RegeneratedHealth;
			TotalRegeneratingHealth += RegeneratedHealth;
		}

		if (HealthSettings.bDisplayHealth)
			Player.SetCapabilityAttributeValue(n"AudioHealthRegen", RegeneratedHealth);
	}

	private void KillPlayer()
	{
		Telemetry::TriggerGameEvent(Player, n"Death");

		DiedAtLocation.Fill(Player);
		bIsDead = true;
		GameTimeAtLastDeath = Time::GetGameTimeSeconds();
		OnPlayerDied.ExecuteIfBound(Player);

		Player.SetCapabilityActionState(n"AudioPlayerDied", EHazeActionState::ActiveForOneFrame);
	}

	bool IsBeingForcedAlive()
	{
		if (bForceAlive)
			return true;
		if (Player.bIsControlledByCutscene)
			return true;
		return false;
	}

	void DeactivateDamageEffects()
	{
		for (auto DamageEffect : ActiveDamageEffects)
		{
			if (DamageEffect.bActive)
				DamageEffect.Deactivate();
		}
        ActiveDamageEffects.Empty();
	}

	void DeactivateDeathEffects()
	{
		for (auto DeathEffect : ActiveDeathEffects)
		{
			if (DeathEffect.bActive)
				DeathEffect.Deactivate();
		}
        ActiveDeathEffects.Empty();
	}

	void ResetHealth()
	{
		CurrentHealth = 1.f;
		RecentlyLostHealth = 0.f;
		GameTimeAtMostRecentDamage = -1.f;
		RecentlyHealedHealth = 0.f;
		bStartedDamageCharge = false;
		GameTimeAtMostRecentHeal = -1.f;
		RecentlyRegeneratedHealth = 0.f;
		TotalRegeneratingHealth = 0.f;
		bStartedHealCharge = false;
		bIsDead = false;
		bForceAlive = false;
	}

	void FlashInvulnerability(FLinearColor Color, float PulseDuration, float PulseInterval)
	{
		bFlashInvulnerability = true;
		FlashColor = Color;
		FlashPulseDuration = PulseDuration;
		FlashPulseInterval = PulseInterval;
		FlashTimer = 0.f;
		NextFlash = 0.f;
	}

	void LeaveDeathCrumb(TSubclassOf<UPlayerDeathEffect> DeathEffect, bool bKilledByDamage = false)
	{
		devEnsure(HasControl(), "Cannot leave death crumbs on remote side");
		devEnsure(!bIsDead, "Cannot leave death crumb while already dead");

		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Owner);

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
		CrumbParams.AddObject(n"DeathEffect", DeathEffect.Get());
		CrumbParams.AddNumber(n"ResetCounter", ResetCounter);
		if (bKilledByDamage)
			CrumbParams.AddActionState(n"DiedFromDamage");
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_KillPlayerInstantly"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_KillPlayerInstantly(FHazeDelegateCrumbData CrumbData)
	{
		UClass EffectClass = Cast<UClass>(CrumbData.GetObject(n"DeathEffect"));
		TSubclassOf<UPlayerDeathEffect> DeathEffect = EffectClass;
		if (!DeathEffect.IsValid())
			DeathEffect = GetDefaultEffect_Death();

		bool bIsStale = CrumbData.IsStale();

		if (CrumbData.GetActionState(n"DiedFromDamage"))
			Damage(CurrentHealth);

		if (CrumbData.GetNumber(n"ResetCounter") == ResetCounter)
			KillPlayer();
		else
			bIsStale = true;

		PlayDeathEffect(DeathEffect, bIsStale);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_DamagePlayerHealth(FHazeDelegateCrumbData CrumbData)
	{
		float DamageAmount = CrumbData.GetValue(n"Damage");
		TSubclassOf<UPlayerDamageEffect> DamageEffect = Cast<UClass>(CrumbData.GetObject(n"DamageEffect"));
	
		if (CrumbData.GetNumber(n"ResetCounter") == ResetCounter)
			Damage(DamageAmount);

		PlayDamageEffect(DamageEffect);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_HealPlayerHealth(FHazeDelegateCrumbData CrumbData)
	{
		float HealAmount = CrumbData.GetValue(n"HealAmount");
		if (CrumbData.GetNumber(n"ResetCounter") == ResetCounter)
			Heal(HealAmount);
	}
};