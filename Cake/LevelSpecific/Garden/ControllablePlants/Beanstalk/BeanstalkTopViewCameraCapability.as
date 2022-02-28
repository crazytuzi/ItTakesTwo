import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkTopViewCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::OptionalChaseAssistance);
	default CapabilityTags.Add(n"Beanstalk");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UCameraLazyChaseSettings ChaseSettings;

	AHazePlayerCharacter Player;
	UCameraUserComponent User;
	UControllablePlantsComponent PlantComp;
	ABeanstalk Beanstalk;
	UBeanstalkCameraSpringArmSettingsDataAsset BeanstalkCameraSettings;
	UBeanstalkSettings BeanstalkSettings;

	float NoInputDuration = 0.0f;
	float MovementDuration = 0.0f;

	FHazeAcceleratedFloat PitchAxis;
	FHazeAcceleratedFloat YawAxis;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);
		PlantComp = UControllablePlantsComponent::Get(Owner);
		ChaseSettings = UCameraLazyChaseSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlantComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		ABeanstalk TempStalk = Cast<ABeanstalk>(PlantComp.CurrentPlant);

		if(TempStalk == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!TempStalk.bUseTopViewCamera)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Beanstalk = Cast<ABeanstalk>(PlantComp.CurrentPlant);
		if (User != nullptr)
		{
			User.RegisterDesiredRotationReplication(this);
		}
			
		BeanstalkCameraSettings = Beanstalk.CameraSettings;
		BeanstalkSettings = Beanstalk.BeanstalkSettings;

		if(Beanstalk.CameraLazyChaseSettings != nullptr)
		{
			Owner.ApplySettings(Beanstalk.CameraLazyChaseSettings, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlantComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Beanstalk.bUseTopViewCamera)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeDilation = Owner.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		UpdateInputDuration(RealTimeDeltaSeconds);

		FRotator WantRotation = User.WorldToLocalRotation(TargetRotation);
		WantRotation.Yaw = Beanstalk.TopViewYawAngle;

		FRotator DesiredRotation = User.WorldToLocalRotation(User.GetDesiredRotation());
		float CameraDot = 1.2f - DesiredRotation.Vector().DotProduct(-FVector::UpVector);

		PitchAxis.Value = DesiredRotation.Pitch;
		YawAxis.Value = DesiredRotation.Yaw;

		PitchAxis.AccelerateTo(WantRotation.Pitch, GetAccelerationDuration(), DeltaTime);

		FRotator DeltaAxis = (WantRotation - FRotator(0, YawAxis.Value, 0)).GetNormalized();
		YawAxis.AccelerateTo(YawAxis.Value + DeltaAxis.Yaw, GetAccelerationDuration() * CameraDot, DeltaTime);

		FRotator DeltaRot = (FRotator(PitchAxis.Value, YawAxis.Value, 0) - DesiredRotation).GetNormalized();
		DeltaRot.Roll = 0.f;

		User.AddDesiredRotation(DeltaRot);
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		NoInputDuration = (AxisInput.IsNearlyZero(0.001f) ? NoInputDuration + DeltaTime : 0.0f);
		MovementDuration = (IsMoving() ? MovementDuration + DeltaTime : 0.0f);
	}

	FRotator GetTargetRotation() const property
	{
		const FRotator WantedRotation = (-FVector::UpVector).Rotation();


		return WantedRotation + FRotator(BeanstalkSettings.TopViewCameraPitchOffset, 0, 0);
	}

	bool IsMoving() const
	{
		return FMath::Abs(Beanstalk.GetCurrentMovementDirection()) > 0.0f;
	}

	float GetAccelerationDuration() const property
	{
		return ChaseSettings.AccelerationDuration;
	}
}
