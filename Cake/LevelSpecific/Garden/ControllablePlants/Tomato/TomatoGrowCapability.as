import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

class UTomatoGrowCapability : UHazeCapability
{
	
	float MaxScale = 2.5f;
	float GrowSpeed = 0.1f;

	UWaterHoseImpactComponent WaterHoseImpact;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WaterHoseImpact = UWaterHoseImpactComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WaterHoseImpact.bBeeingHitByWater && Owner.ActorScale3D.Z <= MaxScale)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.DisableTransformSynchronization();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!WaterHoseImpact.bBeeingHitByWater)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewScale = FMath::Min(Owner.ActorScale3D.Z + (GrowSpeed * DeltaTime), MaxScale);
		Owner.SetActorScale3D(NewScale);
	}
}
