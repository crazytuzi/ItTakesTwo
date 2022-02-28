import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Capabilities.CameraTags;

class UCameraLazyChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::ChaseAssistance);
	default CapabilityTags.Add(CameraTags::OptionalChaseAssistance);

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::GamePlay;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	FHazeAcceleratedRotator ChaseRotation;
	FHazeAcceleratedFloat AccelerationDuration;
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
		ChaseRotation.SnapTo(User.WorldToLocalRotation(GetTargetRotation()));
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

		const float RealTimeDeltaSeconds = GetDeltaTimeForDelayUpdates(DeltaTime);
		UpdateInputDuration(RealTimeDeltaSeconds);
		if (NoInputDuration <= Settings.CameraInputDelay)	
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}

		FRotator DesiredRot = User.WorldToLocalRotation(GetDesiredRotation()); 
		FRotator TargetRot = User.WorldToLocalRotation(GetTargetRotation());

		float SpeedFactor = 1.f;
		if (Settings.ChaseFactorByAngleCurve != nullptr)
		{
			// Only care about yaw for now
			float AngleDiff = FMath::Abs(FRotator::NormalizeAxis(TargetRot.Yaw - DesiredRot.Yaw));
			SpeedFactor *= GetSpeedFactorMultiplier(AngleDiff);
		}

		if (SpeedFactor < 0.01f)
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}

		AccelerationDuration.AccelerateTo(Settings.AccelerationDuration / SpeedFactor, 1.f, RealTimeDeltaSeconds);

		ChaseRotation.Value = DesiredRot; // This value is expected to be changed by outside systems
		if ((MovementDuration > Settings.MovementInputDelay) && SettingsAllowChaseCamera())
		{
			ChaseRotation.AccelerateTo(TargetRot, AccelerationDuration.Value, DeltaTime);
		}
		else
		{
			// Allow velocity to decelerate to 0
			ChaseRotation.Velocity -= ChaseRotation.Velocity * 10.f * DeltaTime;
			ChaseRotation.Value += ChaseRotation.Velocity * DeltaTime;
		}
		
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
		User.AddDesiredRotation(FinalizeDeltaRotation(RealTimeDeltaSeconds, DeltaRot));
	}

	float GetDeltaTimeForDelayUpdates(float DeltaTime) const
	{
		float TimeDilation = PlayerUser.GetActorTimeDilation();
		return (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
	}

	float GetSpeedFactorMultiplier(float AngleDiff) const
	{
		return Settings.ChaseFactorByAngleCurve.GetFloatValue(AngleDiff);
	}

	FRotator GetDesiredRotation()const
	{
		return User.GetDesiredRotation();
	}

	FRotator FinalizeDeltaRotation(float DeltaTime, FRotator DeltaRot)
	{
		FRotator FinalDeltaRot;
		FinalDeltaRot.Yaw = DeltaRot.Yaw;
		return FinalDeltaRot;
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

	FRotator GetTargetRotation()
	{
		return Settings.ChaseOffset.Compose(Owner.GetActorRotation());
	}

	FVector2D GetInput() const
	{
		return GetAttributeVector2D(AttributeVectorNames::CameraDirection);
	}

	bool IsMoving() const
	{
		//const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		//return !AxisInput.IsNearlyZero(0.01f);
		FVector MoveUp = PlayerUser.GetMovementWorldUp();

		FVector Velocity;
		Velocity = PlayerUser.GetActualVelocity();

		/*FVector ParentsVelocity;
		if (Cast<UPrimitiveComponent>(ActiveSwingPoint.GetAttachParent()) != nullptr)
			ParentsVelocity = Cast<UPrimitiveComponent>(ActiveSwingPoint.GetAttachParent()).GetPhysicsLinearVelocity();*/

		UPrimitiveComponent MoveWithPrimitive;
		if ((MoveComp != nullptr) && MoveComp.GetCurrentMoveWithComponent(MoveWithPrimitive, FVector()))
			Velocity -= MoveWithPrimitive.GetPhysicsLinearVelocity() * (1 -Settings.InheritedVelocityFactor);

		return Velocity.ConstrainToPlane(MoveUp).SizeSquared2D() > FMath::Square(Settings.MovementThreshold);
	}

	bool SettingsAllowChaseCamera()
	{
		auto CurrentCamera = User.GetCurrentCamera();
		if(CurrentCamera == nullptr)
			return false;

		FHazeCameraSettings CamSettings;
		User.GetCameraSettings(CamSettings);
		CamSettings.Override(CurrentCamera.Settings);
		if (!CamSettings.bAllowChaseCamera)
			return false;		

		return true;
	}
};