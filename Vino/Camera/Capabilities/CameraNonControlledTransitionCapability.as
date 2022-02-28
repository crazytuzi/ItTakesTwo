import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraPointOfInterestRotationComponent;

// Handle transition from a non-controlled camera to controlled camera so 
// we don't get weird behaviour during blend
class UCameraNonControlledTransitionCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	UHazeCameraComponent NonControlledCamera;
	UHazeCameraComponent POICamera;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::NonControlled);
	default CapabilityTags.Add(CameraTags::NonControlledTransition);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityDebugCategory = CameraTags::Camera;

	FHazeAcceleratedFloat SensitivityFactor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// This modifies input, so must only be active on control side
		if (!User.HasControl())
			return EHazeNetworkActivation::DontActivate;

		// Activate when blending to a camera not controlled by input
		UHazeCameraComponent CurCam = User.GetCurrentCamera();
		if (CurCam == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (CurCam.IsControlledByInput())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!User.HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		// Deactivate once last non-controlled camera has finished blending out
		if (NonControlledCamera == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		UHazeCameraComponent CurCam = User.GetCurrentCamera();
		if (CurCam == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (CurCam.IsControlledByInput() && (NonControlledCamera.CameraState == EHazeCameraState::Inactive))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		NonControlledCamera = User.GetCurrentCamera();
		SensitivityFactor.SnapTo(0.f);

		// Set a point of interest matching the camera to minimize weirdness when blending in to camera
		ApplyPointOfInterest(NonControlledCamera);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerUser.ClearCameraSettingsByInstigator(this);
		PlayerUser.ClearPointOfInterestByInstigator(this);
		POICamera = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeCameraComponent CurCam = User.GetCurrentCamera();
		float RemainingBlendTime = PlayerUser.GetRemainingBlendTime(CurCam);
		float ClampedBlendTime = FMath::Max(0.5f, RemainingBlendTime);
		if (CurCam.IsControlledByInput())
		{
			// Blending in controlled camera, increase sensitivity factor
			SensitivityFactor.AccelerateTo(GetAngleAdjustedSensitivityFactor(ClampedBlendTime), ClampedBlendTime, DeltaTime);
			PlayerUser.ClearPointOfInterestByInstigator(this);
			POICamera = nullptr;
		}
		else
		{
			// Still using non-controlled camera, decrease sensitivity factor
			if (CurCam != POICamera)
				ApplyPointOfInterest(CurCam);
			NonControlledCamera	= CurCam;
			SensitivityFactor.AccelerateTo(0.f, ClampedBlendTime, DeltaTime);
		}

		// Since we're changing blend time we need to clear settings
		// before applying or we'll get multiple entries
		PlayerUser.ClearCameraSettingsByInstigator(this);

		FHazeCameraSettings Settings;
		Settings.bUseSensitivityFactor = true;
		Settings.SensitivityFactor = SensitivityFactor.Value;
		PlayerUser.ApplySpecificCameraSettings(Settings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend::Normal(ClampedBlendTime), this, EHazeCameraPriority::High);
	}	

	float GetAngleAdjustedSensitivityFactor(float RemainingTime)
	{
		// Soft clamp by reducing sensitivity when far from the non-controlled camera's yaw
		FRotator LocalNonControlledRot = User.WorldToLocalRotation(NonControlledCamera.GetViewRotation());
		FRotator LocalDesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation());
		float Diff = FMath::Abs(FRotator::NormalizeAxis(LocalNonControlledRot.Yaw - LocalDesiredRot.Yaw));
		float Dampening = FMath::GetMappedRangeValueClamped(FVector2D(15.f, 45.f), FVector2D(0.f, 1.f), Diff);
		Dampening *= FMath::GetMappedRangeValueClamped(FVector2D(0.f, 0.5f), FVector2D(0.f, 1.f), RemainingTime);
		return 1.f - Dampening;
	}

	void ApplyPointOfInterest(UHazeCameraComponent Camera)
	{
		POICamera = Camera;
		if (User.GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent>(UCameraPointOfInterestRotationComponent::StaticClass())) != nullptr)
		{
			PlayerUser.ClearPointOfInterestByInstigator(this);
			return;
		}

		FHazePointOfInterest POI;
		POI.FocusTarget.Component = Camera;
		POI.bMatchFocusDirection = true;
		POI.TurnScaling.Pitch = 0.f; // Only follow yaw
		POI.Blend.BlendTime = FMath::Max(0.5f, PlayerUser.GetRemainingBlendTime(Camera));
		PlayerUser.ApplyPointOfInterest(POI, this, EHazeCameraPriority::Low);
	}
}

