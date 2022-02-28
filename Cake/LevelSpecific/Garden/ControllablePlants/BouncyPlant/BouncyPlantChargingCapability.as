import Cake.LevelSpecific.Garden.ControllablePlants.BouncyPlant.BouncyPlant;

class UBouncyPlantChargingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 8;
	
	ABouncyPlant BouncyPlant;

	float ShakeAmount = 20.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		BouncyPlant = Cast<ABouncyPlant>(Owner);
		//CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BouncyPlant.FireRate > 0)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BouncyPlant.bIsCharging = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BouncyPlant.FireRate <= 0)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BouncyPlant.HasControl())
		{
			BouncyPlant.SyncChargeProgress.Value = BouncyPlant.ChargeAlpha;
			//BouncyPlant.SyncSize.Value = BouncyPlant.PlantMesh.GetRelativeScale3D();
			//BouncyPlant.SyncSize.Value = BouncyPlant.PlantMesh.GetRelativeScale3D();

			float ChargeAlpha = BouncyPlant.ChargeAlpha;
			ChargeAlpha += BouncyPlant.ChargeSpeed * DeltaTime;
			ChargeAlpha = FMath::Clamp(ChargeAlpha, 0.0f, 1.0f);
			BouncyPlant.ChargeAlpha = ChargeAlpha;

			// float PlantZSize = FMath::Lerp(1.0f, 0.5f, ChargeAlpha);
			// BouncyPlant.PlantMesh.SetRelativeScale3D(FVector(1.0f, 1.0f, PlantZSize));

			// if(ChargeAlpha >= 1.0f)
			// {
			// 	BouncyPlant.PlantMesh.SetRelativeLocation(FVector(FMath::RandRange(-ShakeAmount, ShakeAmount), FMath::RandRange(-ShakeAmount, ShakeAmount), 0.0f));
			// }
		}
		else
		{
			BouncyPlant.ChargeAlpha = BouncyPlant.SyncChargeProgress.Value;
			// BouncyPlant.PlantMesh.SetRelativeScale3D(BouncyPlant.SyncSize.Value);

			// if(FMath::IsNearlyEqual(BouncyPlant.ChargeAlpha, 1.0f, 0.01f))
			// {
			// 	BouncyPlant.PlantMesh.SetRelativeLocation(FVector(FMath::RandRange(-ShakeAmount, ShakeAmount), FMath::RandRange(-ShakeAmount, ShakeAmount), 0.0f));
			// }
		}
	}
}
