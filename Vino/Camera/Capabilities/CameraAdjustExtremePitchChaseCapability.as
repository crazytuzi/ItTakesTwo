import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;

class UCameraAdjustExtremePitchChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);
	default CapabilityTags.Add(CameraTags::OptionalChaseAssistance);
	default CapabilityTags.Add(n"CameraAdjustExtremePitch");
	default CapabilityTags.Add(n"PlayerDefault");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::GamePlay;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	FHazeAcceleratedFloat ChasePitch;
	UCameraLazyChaseSettings Settings;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		Settings = UCameraLazyChaseSettings::GetSettings(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!User.HasControl() && !PlayerUser.CameraSyncronizationIsBlocked())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!User.HasControl() && !PlayerUser.CameraSyncronizationIsBlocked())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		User.RegisterDesiredRotationReplication(this);
		ChasePitch.SnapTo(GetLocalDesiredPitch());
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return;
	
		float TimeDilation = PlayerUser.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		UpdateInputDuration(RealTimeDeltaSeconds);
		if (NoInputDuration <= Settings.CameraInputDelay)	
		{
			ChasePitch.Velocity = 0.f;
			return;
		}

		FHazeCameraSpringArmSettings SpringArmSettings;
		User.GetCameraSpringArmSettings(SpringArmSettings);

		float DesiredPitchLocal = GetLocalDesiredPitch();
		ChasePitch.Value = DesiredPitchLocal; // This value is expected to be changed by outside systems
		if (ShouldAdjustPitch(DesiredPitchLocal, SpringArmSettings.ChasePitchUp, SpringArmSettings.ChasePitchDown))
		{
			if (DesiredPitchLocal > SpringArmSettings.ChasePitchUp) 
				ChasePitch.AccelerateTo(SpringArmSettings.ChasePitchUp, 5.f, DeltaTime);
			else 
				ChasePitch.AccelerateTo(SpringArmSettings.ChasePitchDown, 10.f, DeltaTime);
		}
		else
		{
			// Allow velocity to decelerate to 0
			ChasePitch.Velocity -= ChasePitch.Velocity * 2.f * DeltaTime;
			ChasePitch.Value += ChasePitch.Velocity * DeltaTime;
		}
		
		float DeltaPitch = FRotator::NormalizeAxis(ChasePitch.Value - DesiredPitchLocal);
		User.AddDesiredRotation(FRotator(DeltaPitch, 0.f, 0.f));
	}

	bool ShouldAdjustPitch(float CurPitch, float TargetPitchUp, float TargetPitchDown)
	{
		if (MovementDuration < Settings.MovementInputDelay)
			return false;	

		if (User.IsAiming())
			return false;
		
		if (!User.IsUsingDefaultCamera())
			return false;

		FHazeCameraSettings CamSettings;
		User.GetCameraSettings(CamSettings);
		CamSettings.Override(User.GetCurrentCamera().Settings);
		if (!CamSettings.bAllowChaseCamera)
			return false;		

		// Should we pitch down?
		if (CurPitch > TargetPitchUp)
			return true;

		// Should we pitch up?
		if (CurPitch < -TargetPitchDown)
			return true;

		return false;
	}

	float GetLocalDesiredPitch()
	{
		FRotator DesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation()); 
		return FRotator::NormalizeAxis(DesiredRot.Pitch);
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetInput();
		if (AxisInput.IsNearlyZero(0.001f))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.f;

		if (IsMoving())
			MovementDuration += DeltaTime;
		else
			MovementDuration = 0.f;
	}

	FVector2D GetInput() const
	{
		return GetAttributeVector2D(AttributeVectorNames::CameraDirection);
	}

	bool IsMoving() const
	{
		FVector MoveUp = PlayerUser.GetMovementWorldUp();

		FVector Velocity;
		Velocity = PlayerUser.GetActualVelocity();

		UPrimitiveComponent MoveWithPrimitive;
		if ((MoveComp != nullptr) && MoveComp.GetCurrentMoveWithComponent(MoveWithPrimitive, FVector()))
			Velocity -= MoveWithPrimitive.GetPhysicsLinearVelocity() * (1 -Settings.InheritedVelocityFactor);

		return Velocity.ConstrainToPlane(MoveUp).SizeSquared2D() > FMath::Square(Settings.MovementThreshold);
	}
}

