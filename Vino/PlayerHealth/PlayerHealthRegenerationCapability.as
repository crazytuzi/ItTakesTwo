import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthSettings;

class UPlayerHealthRegenerationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HealthRegeneration");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerHealthSettings HealthSettings;

	float GameTimeLastRegeneration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	float GetTargetHealth() const
	{
		return 1.f;
		
		// int TargetChunk = FMath::CeilToInt(HealthComp.CurrentHealth * float(HealthSettings.HealthChunks));
		// return float(TargetChunk) * (1.f / float(HealthSettings.HealthChunks));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HealthSettings.bRegenerateToHealthChunk && HealthSettings.bDisplayHealth)
			return EHazeNetworkActivation::DontActivate;

		if (HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;

		if (Time::GetGameTimeSince(HealthComp.GameTimeAtMostRecentDamage) < HealthSettings.RegenerationDelay)
			return EHazeNetworkActivation::DontActivate;

		if (Time::GetGameTimeSince(HealthComp.GameTimeAtMostRecentHeal) < HealthSettings.RegenerationDelay)
			return EHazeNetworkActivation::DontActivate;

		if (Time::GetGameTimeSince(GameTimeLastRegeneration) < HealthSettings.RegenerationDelay)
			return EHazeNetworkActivation::DontActivate;

		if (FMath::IsNearlyEqual(HealthComp.CurrentHealth, GetTargetHealth()))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		GameTimeLastRegeneration = Time::GetGameTimeSeconds();
		HealthComp.Regenerate(GetTargetHealth() - HealthComp.CurrentHealth);
	}
};