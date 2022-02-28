import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledBoost);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	const float BoostDuration = 3.f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);

		// Bind boost delegate
		BoatsledComponent.BoatsledEventHandler.OnBoatsledBoost.AddUFunction(this, n"OnBoatsledBoost");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkActivation::DontActivate;

		if(!BoatsledComponent.IsBoosting())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		// Increase maximum boatsled speed while capability is active
		BoatsledComponent.SetBoatsledMaxSpeed(BoatsledComponent.Boatsled.MaxSpeed * 1.15f);
		PlayerOwner.ApplyFieldOfView(110.f, 1.f, this);
	}

	// BoatsledMovementCapability will drastically reduce friction as long as this capability is active
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= BoostDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// We don't want to boost while we're jumping
		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FCapabilityDeactivationParams& DeactivationParams)
	{
		// Restore max speed to original
		BoatsledComponent.SetBoatsledMaxSpeed(BoatsledComponent.Boatsled.MaxSpeed);
		PlayerOwner.ClearFieldOfViewByInstigator(this, 2.f);

		BoatsledComponent.StopBoosting();

		if(BoatsledComponent.Boatsled.BoostEffect != nullptr)
			BoatsledComponent.Boatsled.BoostEffect.Deactivate();

		ElapsedTime = 0.f;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledBoost()
	{
		// Reset elapsed time in case we're going through several boosts
		ElapsedTime = 0.f;

		// Enable or reset effect depending on state
		if(BoatsledComponent.Boatsled.BoostEffect != nullptr)
		{
			if(BoatsledComponent.Boatsled.BoostEffect.IsActive())
				BoatsledComponent.Boatsled.BoostEffect.ResetSystem();
			else
				BoatsledComponent.Boatsled.BoostEffect.Activate();
		}
	}
}