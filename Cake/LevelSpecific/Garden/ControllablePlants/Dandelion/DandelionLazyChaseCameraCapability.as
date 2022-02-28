import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraLazyChaseSettings;
import Vino.Camera.Capabilities.CameraLazyChaseCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;

class UDandelionLazyCameraChaseCapability : UCameraLazyChaseCapability
{
	default CapabilityTags.Add(n"Dandelion");

	UControllablePlantsComponent PlantComp;
	ADandelion Dandelion;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		PlantComp = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		ADandelion TempDand = Cast<ADandelion>(PlantComp.CurrentPlant);

		if(TempDand == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(TempDand.bActivateLaunchCamera)
			return EHazeNetworkActivation::DontActivate;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Dandelion = Cast<ADandelion>(PlantComp.CurrentPlant);
		Super::OnActivated(ActivationParams);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
		
		if(Dandelion.CameraLazyChaseSettings != nullptr)
			Owner.ApplySettings(Dandelion.CameraLazyChaseSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Super::OnDeactivated(DeactivationParams);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const override
	{
		ADandelion TempDand = Cast<ADandelion>(PlantComp.CurrentPlant);

		if(TempDand == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TempDand.bActivateLaunchCamera)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return Super::ShouldDeactivate();
	}

	bool IsMoving() const override
	{
		return Dandelion.HorizontalVelocity.SizeSquared() > 0.1f;
	}

	FRotator GetTargetRotation() override
	{
		if(Dandelion.HorizontalVelocity.IsNearlyZero())
			return Dandelion.Camera.ForwardVector.Rotation();

		return Dandelion.HorizontalVelocity.GetSafeNormal().Rotation();
	}
}
