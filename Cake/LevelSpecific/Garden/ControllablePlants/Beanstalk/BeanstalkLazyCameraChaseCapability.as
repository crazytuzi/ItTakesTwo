import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Vino.Camera.Settings.CameraLazyChaseSettings;
import Vino.Camera.Capabilities.CameraLazyChaseCapability;

class UBeanstalkLazyCameraChaseCapability : UCameraLazyChaseCapability
{
	default CapabilityTags.Add(n"Beanstalk");

	UControllablePlantsComponent PlantComp;
	ABeanstalk Beanstalk;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		PlantComp = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		ABeanstalk TempStalk = Cast<ABeanstalk>(PlantComp.CurrentPlant);

		if(TempStalk == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(TempStalk.CurrentState == EBeanstalkState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Beanstalk = Cast<ABeanstalk>(PlantComp.CurrentPlant);
		Super::OnActivated(ActivationParams);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
		
		if(Beanstalk.CameraLazyChaseSettings != nullptr)
			Owner.ApplySettings(Beanstalk.CameraLazyChaseSettings, this);
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
		ABeanstalk TempStalk = Cast<ABeanstalk>(PlantComp.CurrentPlant);

		if(TempStalk == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TempStalk.CurrentState == EBeanstalkState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return Super::ShouldDeactivate();
	}

	bool IsMoving() const override
	{
		return FMath::Abs(Beanstalk.CurrentVelocity) > 0.1f;
	}

	FRotator GetTargetRotation() override
	{
		return Beanstalk.HeadRotationNode.ForwardVector.Rotation();
	}
}
