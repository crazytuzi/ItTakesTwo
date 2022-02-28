import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// TODO: Mouse input currently doesn't _really_ work,
// we should probably create a separate way of handling that someday. Someday.
class UCameraVehicleControlCapability : UHazeCapability
{
	UCameraUserComponent User;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::Control);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(n"Vehicle");

	default CapabilityTags.Add(n"Input");
	default CapabilityTags.Add(n"StickInput");

	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = CameraTags::Camera;

	FQuat CurrentRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);

		SetMutuallyExclusive(CameraTags::Control, true);
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);

		SetMutuallyExclusive(CameraTags::Control, false);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		User.SetYawAxis(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
		{
			// On the slave-side, just set yaw axis
			// 10/06 commented this out because it causes remote side to be super jittery
			//FQuat OwnerSpace = Math::MakeQuatFromX(Owner.ActorForwardVector);
			//User.SetYawAxis(OwnerSpace.UpVector);
			return;
		}

		CurrentRotation = User.DesiredRotation.Quaternion();

		const float TimeDilation = Owner.GetActorTimeDilation();
		const float UndilatedDeltaTime = TimeDilation > 0.f ? DeltaTime / TimeDilation : 1.f; // We could save real time i between ticks instead, but probably not necessary

		// Get camera settings
		FHazeCameraClampSettings Settings;
		User.GetClampSettings(Settings);

		// We dont allow more than 90 degree rotation. Fix??? @Olsson
		Settings.ClampYawLeft = FMath::Clamp(Settings.ClampYawLeft, -90.f, 90.f);
		Settings.ClampYawRight = FMath::Clamp(Settings.ClampYawRight, -90.f, 90.f);
		Settings.ClampPitchDown = FMath::Clamp(Settings.ClampPitchDown, -90.f, 90.f);
		Settings.ClampPitchUp = FMath::Clamp(Settings.ClampPitchUp, -90.f, 90.f);

		// Apply clamps
		FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (AxisInput.X > 0.f)
			AxisInput.X *= Settings.bUseClampYawRight ? Settings.ClampYawRight : 89.9f;
		else
			AxisInput.X *= Settings.bUseClampYawLeft ? Settings.ClampYawLeft : 89.9f;
		
		if (AxisInput.Y > 0.f)
			AxisInput.Y *= Settings.bUseClampPitchUp ? Settings.ClampPitchUp : 89.9f;
		else
			AxisInput.Y *= Settings.bUseClampPitchDown ? Settings.ClampPitchDown : 89.9f;

		FQuat TargetRotation = FRotator(AxisInput.Y, AxisInput.X, 0.f).Quaternion();

		// Transform rotation from plane-space to world-space
		FQuat OwnerSpace = Math::MakeQuatFromX(Owner.ActorForwardVector);
		TargetRotation = OwnerSpace * TargetRotation;

		// Lerp our current rotation
		CurrentRotation = FQuat::Slerp(CurrentRotation, TargetRotation, 2.5f * UndilatedDeltaTime);
		CurrentRotation.Normalize();

		// Go bananas!
		User.SetYawAxis(OwnerSpace.UpVector);
		User.SetDesiredRotation(CurrentRotation.Rotator());
	}
};