import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatHealthRegenCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PiratesHealthRegen");

	default CapabilityDebugCategory = n"Pirate";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AWheelBoatActor WheelBoatActor;

	const float TimeBetweenTicks = 10.5f;
	const float HealthPerTick = 1.f;
	float CooldownTimer = TimeBetweenTicks;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WheelBoatActor = Cast<AWheelBoatActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (FMath::IsNearlyEqual(WheelBoatActor.Health, 1.f))
			CooldownTimer = TimeBetweenTicks;
		else
			CooldownTimer -= DeltaTime;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WheelBoatActor.Health <= 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (CooldownTimer > 0.f)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
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

		// float Healing = HealthPerSecond * TimeBetweenTicks;
		WheelBoatActor.AddHealth(HealthPerTick);
	}
}