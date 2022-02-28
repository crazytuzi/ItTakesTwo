import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;

class UTurretPlantAmmoReloadCapability : UHazeCapability
{
	ATurretPlant TurretPlant;
	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(IsActioning(n"TurretPlantReload") && TurretPlant.CanReload())
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		if(TurretPlant.HasEnoughAmmoToShoot())
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"TurretPlantReload_Audio", EHazeActionState::Active);
		TurretPlant.StopSpikeAnimation();
		TurretPlant.RestoreAmmo();
		TurretPlant.bIsReloading = true;
		Elapsed = TurretPlant.AmmoReloadTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TurretPlant.bIsReloading = false;
		TurretPlant.SetupSpikeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed <= 0.0f)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;
	}
}
