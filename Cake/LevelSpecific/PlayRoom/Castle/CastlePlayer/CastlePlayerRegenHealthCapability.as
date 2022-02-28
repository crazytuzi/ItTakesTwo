import Vino.PlayerHealth.PlayerHealthStatics;

class UCastlePlayerRegenHealthCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Castle");

	default CapabilityDebugCategory = n"Castle";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;

	const float TimeBetweenTicks = 2.f;
	const float HealthPerSecond = 0.06;
	float CooldownTimer = TimeBetweenTicks;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (FMath::IsNearlyEqual(HealthComp.CurrentHealth, 1.f))
			CooldownTimer = TimeBetweenTicks;
		else
			CooldownTimer -= DeltaTime;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;

		if (CooldownTimer > 0.f)
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
		CooldownTimer = TimeBetweenTicks;

		float Healing = HealthPerSecond * TimeBetweenTicks;
		Player.HealPlayerHealth(Healing);

		if(HealthComp.CurrentHealth == 1)
			Player.SetCapabilityAttributeValue(n"AudioHealthRegen", Healing);
	}
}