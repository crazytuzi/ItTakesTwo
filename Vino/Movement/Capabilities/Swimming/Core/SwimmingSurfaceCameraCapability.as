import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;

class USwimmingSurfaceCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);

	default CapabilityDebugCategory = n"NewGrinding";	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;

	FAcceleratedCameraDesiredRotation AcceleratedCameraDesiredRotation;
	FVector DefaultPivotOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);

		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
		DefaultPivotOffset = Settings.PivotOffset;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwimComp.SwimmingState != ESwimmingState::Surface)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp.SwimmingState != ESwimmingState::Surface)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedCameraDesiredRotation.Reset(CameraComp.WorldRotation);

		if (SwimComp.SurfaceCameraSettings != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Player.ApplyCameraSettings(SwimComp.SurfaceCameraSettings, Blend, this, EHazeCameraPriority::Medium);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraComp.SetRelativeRotation(FRotator::ZeroRotator);
		Player.ClearCameraSettingsByInstigator(this, 2.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		// FHazeSplineSystemPosition CameraLookAtSystemPosition = UserGrindComp.SplinePosition;
		// FVector CameraLookAtLocation;

		// float RemainingMoveAmount = 0.f;
		// if (!CameraLookAtSystemPosition.Move(1800.f, RemainingMoveAmount))
		// 	CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation + (CameraLookAtSystemPosition.WorldForwardVector * RemainingMoveAmount);
		// else
		// 	CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation;

		// FVector CameraLocation = Player.ViewLocation;

		// FVector ToTarget = CameraLookAtLocation - CameraLocation;

		// ToTarget.Z *= 0.8f;
		// FRotator CameraRotation = Math::MakeRotFromX(ToTarget);
		// CameraRotation.Roll = 0.f;
		
		// /*
		// 	- If input is given, the auto look at should be disabled
		// 	- If no input is given, the auto look at should accerate in over time
		// */		
		// if (GetAttributeVector(AttributeVectorNames::CameraDirection).IsNearlyZero())
		// 	AcceleratedLookAtScale.AccelerateTo(1.f, 2.5f, DeltaTime);
		// else
		// 	AcceleratedLookAtScale.SnapTo(0.f);

		// AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		// AcceleratedTargetRotation.AccelerateTo(CameraRotation, 1.f, DeltaTime * AcceleratedLookAtScale.Value);
		// CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}
}