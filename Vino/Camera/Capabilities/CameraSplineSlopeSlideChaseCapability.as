import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.Capabilities.Sliding.SplineSlopeSlidingSettings;
import Peanuts.Spline.SplineComponent;
import Vino.Movement.Capabilities.Sliding.SlidingNames;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlidingComponent;
import Vino.Camera.Capabilities.CameraTags;

class UCameraSplineSlopeSlideChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	FSplineSlopeCameraSettings Settings;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");

	default CapabilityTags.Add(CameraTags::ChaseAssistance);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	FHazeAcceleratedRotator ChaseRotation;
	FHazeAcceleratedFloat AccelerationDuration;

	UCharacterSlopeSlideComponent SlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);

		SlideComp = UCharacterSlopeSlideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);
		ChaseRotation.SnapTo(GetTargetRotation());
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		
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

		if (NoInputDuration <= Settings.CameraInputDelay || User.IsAiming())
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}

		FTransform ChaseTransform;
		ChaseTransform = Owner.RootComponent.WorldTransform;

		FRotator DesiredRot = User.DesiredRotation;
		FRotator TargetRot = GetRotationTowardsFuturePoint();

		TargetRot.Pitch = Owner.RootComponent.WorldTransform.Rotation.Rotator().Pitch - Settings.TargetPitchOffset;
		TargetRot.Roll = 0.f;

		AccelerationDuration.AccelerateTo(Settings.AccelerationDuration, 1.f, RealTimeDeltaSeconds);

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
	 	
		User.AddDesiredRotation(DeltaRot);
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (AxisInput.IsNearlyZero(0.001f))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.f;

		if (IsMoving())
			MovementDuration += DeltaTime;
		else
			MovementDuration = 0.f;
	}

	FRotator GetRotationTowardsFuturePoint()
	{
		FVector CurrentLocation = Owner.ActorLocation + FVector::UpVector * 500.f;
		const float CurrentDistanceAlongSpline = SlideComp.GuideSpline.GetDistanceAlongSplineAtWorldLocation(CurrentLocation);
		const float FutureDistanceToLookAt = CurrentDistanceAlongSpline + Settings.FutureDistanceToLookAt;
		
		FVector WorldLookationToLookAt = SlideComp.GuideSpline.GetLocationAtDistanceAlongSpline(FutureDistanceToLookAt, ESplineCoordinateSpace::World);
		//System::DrawDebugSphere(WorldLookationToLookAt, 50.f, 12, FLinearColor::Red);

		return (WorldLookationToLookAt - CurrentLocation).Rotation();
	}

	FRotator GetTargetRotation()
	{
		return Owner.GetActorRotation();
	}

	bool IsMoving()
	{
		//const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		//return !AxisInput.IsNearlyZero(0.01f);
		return PlayerUser.GetActualVelocity().SizeSquared2D() > 0.001f;
	}

	bool SettingsAllowChaseCamera()
	{
		FHazeCameraSettings CameraSettings;
		User.GetCameraSettings(CameraSettings);
		CameraSettings.Override(User.GetCurrentCamera().Settings);
		if (!CameraSettings.bAllowChaseCamera)
			return false;		

		return true;
	}
};
