import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.PlayerHealth.PlayerHealthAudioComponent;

class UPlayerRespawnTimerCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Health";
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;

	const float InitialRespawnTimerDelay = 0.4f;

	// Variables for calculating button mash rate
	float TimingWindow = 0.5f;
	float MashTimer = 0.f;

	int PrevMashCount = 0;
	int MashCount = 0;

	bool bSyncPulse = false;
	float SyncTimer = 0.f;

	float SyncedProgress = 0.f;
	float SyncedSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;
		if (!HealthComp.AreDeathEffectsFinished())
			return EHazeNetworkActivation::DontActivate;
		if (HealthSettings.RespawnTimer <= 0.f)
			return EHazeNetworkActivation::DontActivate;
		if (RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;
		if (RespawnComp.bIsRespawning)
			return EHazeNetworkActivation::DontActivate;
		if (HealthComp.IsBeingForcedAlive())
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!HealthComp.AreDeathEffectsFinished())
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (HealthSettings.RespawnTimer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (RespawnComp.bIsRespawning)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (RespawnComp.bIsGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (HealthComp.IsBeingForcedAlive())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RespawnComp.bWaitingForRespawn = true;

		RespawnComp.GameTimeStartedRespawning = Time::GetGameTimeSeconds();
		RespawnComp.CurrentRespawnProgress = 0.01f;

		RespawnComp.RespawnMashRate = 0.f;
		RespawnComp.bRespawnMashPulse = false;

		AudioHealthComp.bRespawnWidgetActive = true;

		PrevMashCount = 0;
		MashCount = 0;
		MashTimer = 0.f;
		SyncTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > InitialRespawnTimerDelay)
		{
			if (HasControl())
			{
				// Respond to mashing
				if (WasActionStarted(ActionNames::ButtonMash))
				{
					RespawnComp.bRespawnMashPulse = true;
					bSyncPulse = true;
					MashCount += 1;
				}
				else
				{
					RespawnComp.bRespawnMashPulse = false;
				}

				MashTimer += DeltaTime;

				// When a window is filled, copy it over and start a new one
				if (MashTimer >= TimingWindow)
				{
					PrevMashCount = MashCount;
					MashCount = 0;
					MashTimer -= TimingWindow;
				}

				// Phase over from the previous window to the next window as it gets more accurate over time
				float PrevRate = GetRatePerSecond(PrevMashCount, TimingWindow);
				float CurRate = GetRatePerSecond(MashCount, MashTimer);

				RespawnComp.RespawnMashRate = FMath::Lerp(PrevRate, CurRate, MashTimer / TimingWindow);

				// Progress respawn timer
				float CurrentSpeed = FMath::Lerp(
					1.f / FMath::Max(HealthSettings.RespawnMashSlowestPct, 0.001f),
					1.f / FMath::Max(HealthSettings.RespawnMashFastestPct, 0.001f),
					FMath::Clamp(RespawnComp.RespawnMashRate / FMath::Max(HealthSettings.RespawnMashTargetRate, 1.f), 0.f, 1.f));

				RespawnComp.CurrentRespawnProgress += DeltaTime / HealthSettings.RespawnTimer * CurrentSpeed;

				// Send updates through network
				SyncTimer -= DeltaTime;
				if (SyncTimer <= 0.f)
				{
					NetSendMash(bSyncPulse, RespawnComp.CurrentRespawnProgress, CurrentSpeed);
					bSyncPulse = false;
					SyncTimer = 0.05f;
				}
			}
			else
			{
				if (bSyncPulse)
				{
					RespawnComp.bRespawnMashPulse = true;
					bSyncPulse = false;
				}
				else
				{
					RespawnComp.bRespawnMashPulse = false;
				}

				float TargetThreshold = SyncedProgress - (SyncedSpeed * 0.1f);
				if (RespawnComp.CurrentRespawnProgress < TargetThreshold)
				{
					RespawnComp.CurrentRespawnProgress += FMath::Min(
						TargetThreshold,
						RespawnComp.CurrentRespawnProgress + (DeltaTime / HealthSettings.RespawnTimer * SyncedSpeed)
					);
				}

				RespawnComp.CurrentRespawnProgress += DeltaTime / HealthSettings.RespawnTimer * SyncedSpeed;
			}
		}
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendMash(bool bPulse, float Progress, float Speed)
	{
		bSyncPulse = bPulse || bSyncPulse;
		SyncedProgress = FMath::Max(Progress, SyncedProgress);
		SyncedSpeed = Speed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RespawnComp.bWaitingForRespawn = false;
		RespawnComp.RespawnMashRate = 0.f;
		RespawnComp.bRespawnMashPulse = false;
		AudioHealthComp.bRespawnWidgetActive = false;

		SyncedProgress = 0.f;
		SyncedSpeed = 0.f;
		bSyncPulse = false;
	}

	float GetRatePerSecond(int Presses, float Time)
	{
		// Dont divide by 0
		if (Time == 0.f)
			return 0.f;

		return Presses / Time;
	}
};