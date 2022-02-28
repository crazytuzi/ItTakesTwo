import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.PlayerHealth.PlayerHealthStatics;

class UPlayerRespawnCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;

	FPlayerRespawnEvent ActiveEvent;
	UPlayerRespawnEffect ActiveEffect;

	bool bIsRespawned = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	bool IsRespawnTimerFinished() const
	{
		if (HealthSettings.RespawnTimer <= 0.f)
			return true;
		if (HealthComp.IsBeingForcedAlive())
			return true;
		if (RespawnComp.bWaitingForRespawn)
			return RespawnComp.CurrentRespawnProgress >= 1.f;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;
		if (!HealthComp.AreDeathEffectsFinished())
			return EHazeNetworkActivation::DontActivate;
		if (!RespawnComp.CanRespawn() && !HealthComp.IsBeingForcedAlive())
			return EHazeNetworkActivation::DontActivate;
		if (!IsRespawnTimerFinished())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveEffect == nullptr || ActiveEffect.bFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!ActiveEffect.bRespawnTriggered && !HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!RespawnComp.bIsRespawning)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (HealthComp.IsBeingForcedAlive())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FPlayerRespawnEvent Event;
		RespawnComp.PrepareRespawn(Event);

		ActivationParams.AddStruct(n"RespawnEvent", Event);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RespawnComp.bIsRespawning = true;

		ActivationParams.GetStruct(n"RespawnEvent", ActiveEvent);
		bIsRespawned = false;

		if (ActiveEvent.RespawnEffect.IsValid())
			ActiveEffect = Cast<UPlayerRespawnEffect>(NewObject(this, ActiveEvent.RespawnEffect.Get()));
		else
			ActiveEffect = Cast<UPlayerRespawnEffect>(NewObject(this, RespawnComp.GetDefaultEffect_Respawn().Get()));

		ActiveEffect.Player = Player;
		ActiveEffect.WorldContext = Player;
		ActiveEffect.Activate();

		if (ActiveEffect.bInvulnerableDuringEffect)
			AddPlayerInvulnerability(Player, ActiveEffect);

		if (HealthComp.IsBeingForcedAlive())
		{
			FinishRespawn();
			if (ActiveEffect.bActive)
				ActiveEffect.Deactivate();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (!bIsRespawned)
			FinishRespawn();
		if (ActiveEffect.bActive)
			ActiveEffect.Deactivate();
		if (ActiveEffect.bInvulnerableDuringEffect)
			RemovePlayerInvulnerability(Player, ActiveEffect);

		RespawnComp.bIsRespawning = false;
		ActiveEffect = nullptr;
	}

	void FinishRespawn()
	{
		bIsRespawned = true;
		//RespawnComp.bIsRespawning = false;

		Player.TriggerMovementTransition(this);
		if (HealthComp.bIsDead && !HealthComp.IsBeingForcedAlive())
			ActiveEffect.TeleportToRespawnLocation(ActiveEvent);
		ActiveEffect.OnPerformRespawn(ActiveEvent);
		RespawnComp.PerformRespawn(ActiveEvent);

		HealthComp.DeactivateDeathEffects();
		HealthComp.ResetHealth();

		// Mark all health we just gained as regeneration
		HealthComp.RecentlyRegeneratedHealth = 1.f;
		HealthComp.TotalRegeneratingHealth = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveEffect.bActive)
			ActiveEffect.Tick(DeltaTime);

		if (!bIsRespawned && ActiveEffect.bRespawnTriggered)
			FinishRespawn();
	}
};