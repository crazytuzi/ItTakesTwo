import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBushTags;

class USneakyBushCameraSettingsCapability : UHazeCapability
{
	AHazePlayerCharacter PlantOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlantOwner == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"CanApplySneakyBushCameraSettings", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(n"CanApplySneakyBushCameraSettings");
	}
}