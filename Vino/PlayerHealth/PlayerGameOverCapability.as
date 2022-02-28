import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthSettings;

class UPlayerGameOverCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GameOver");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;
	UPlayerRespawnComponent OtherPlayerRespawnComp;
	UPlayerHealthComponent HealthComp;
	UPlayerHealthComponent OtherPlayerHealthComp;

	UPlayerHealthSettings HealthSettings;
	bool bGameOverTriggered = false;
	bool bGameOverFinished = false;

	UPlayerGameOverEffect ActiveEffect;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		OtherPlayerHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(Player.OtherPlayer);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Only one side should be able to decide game over, chosen arbitrarily
		// Note that now there system relying on May being the controller for this!
		if (!Player.HasControl() || Player.IsCody())
			return EHazeNetworkActivation::DontActivate;

		// Cannot be game over if we are already game over
		if (RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;

		if (RespawnComp.bManualGameOverTrigger)
		{
			// Manual game overs will always happen
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			// Can only go game over if the settings allow us
			if (!HealthSettings.bCanGameOver)
				return EHazeNetworkActivation::DontActivate;

			// We are game over if both players are dead at the same time
			if (!HealthComp.bIsDead || !OtherPlayerHealthComp.bIsDead)
				return EHazeNetworkActivation::DontActivate;

			// Cannot be game over while either player is in the process of respawning
			if (RespawnComp.bIsRespawning || OtherPlayerRespawnComp.bIsRespawning)
				return EHazeNetworkActivation::DontActivate;

			// Cannot go gameover in jesus/god mode by dying at the same time
			if (HealthComp.GodMode != EGodMode::Mortal)
				return EHazeNetworkActivation::DontActivate;
		}

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bGameOverFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!RespawnComp.bIsGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bGameOverTriggered = false;
		bGameOverFinished = false;

		RespawnComp.bIsGameOver = true;
		OtherPlayerRespawnComp.bIsGameOver = true;

		if (!RespawnComp.OnGameOver.IsBound())
		{
			ActiveEffect = Cast<UPlayerGameOverEffect>(NewObject(Player, RespawnComp.GetDefaultEffect_GameOver().Get()));
			ActiveEffect.Player = Player;
			ActiveEffect.WorldContext = Owner;
			ActiveEffect.Activate();			
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (ActiveEffect != nullptr)
		{
			if (ActiveEffect.bActive)
				ActiveEffect.Deactivate();
			ActiveEffect.DestroyObject();
			ActiveEffect = nullptr;
		}

		RespawnComp.OnGameOverCompleted.Broadcast();
		OtherPlayerRespawnComp.OnGameOverCompleted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't actually trigger the game over until all death effects have finished
		// playing on both players, so we get a nice flow.
		if (!bGameOverTriggered && HealthComp.AreDeathEffectsFinished() && OtherPlayerHealthComp.AreDeathEffectsFinished())
		{
			bGameOverTriggered = true;
			if (RespawnComp.OnGameOver.IsBound())
			{
				bGameOverFinished = true;
				RespawnComp.OnGameOver.Execute();				
			}
			if (ActiveEffect != nullptr)
				ActiveEffect.OnDeathEffectsFinishedPlaying();
		}

		if (ActiveEffect != nullptr)
		{
			ActiveEffect.Tick(DeltaTime);

			if (ActiveEffect.bFinished && RespawnComp.bIsGameOver)
			{
				bool bTriggerRestart = ActiveEffect.bRestartFromSaveAfterEffect;
				if (ActiveEffect.bActive)
					ActiveEffect.Deactivate();

				ActiveEffect = nullptr;
				bGameOverFinished = true;

				if (bTriggerRestart)
					Save::RestartFromLatestSave();
			}
		}
	}
};