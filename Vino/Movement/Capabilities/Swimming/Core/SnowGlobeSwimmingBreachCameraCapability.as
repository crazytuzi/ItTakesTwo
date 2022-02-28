import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingBreachCameraCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::Breach);
	default CapabilityTags.Add(SwimmingTags::Camera);

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	FHazeAcceleratedRotator ChaseRotation;

	float CameraInputDelay = 0.f;
	float AccelerationDuration = 1.f;

	FVector LandingLocation;
	FVector PreviousHorizontalVelocity;
	float LandingTime;
	USnowGlobeSwimmingComponent SwimComp;
	UHazeMovementComponent MoveComp;

	bool bValidLandingLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(PlayerUser);
		MoveComp = UHazeMovementComponent::GetOrCreate(PlayerUser);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingState != ESwimmingState::Breach && SwimComp.SwimmingState != ESwimmingState::BreachDive && SwimComp.SwimmingState != ESwimmingState::VortexDash)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!bValidLandingLocation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwimComp.SwimmingState != ESwimmingState::Breach && SwimComp.SwimmingState != ESwimmingState::BreachDive && SwimComp.SwimmingState != ESwimmingState::VortexDash)
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

		float FlightTime = 0.f;
		bValidLandingLocation = GetLandingLocation(MoveComp.Velocity, SwimmingSettings::Breach.Gravity, LandingLocation, FlightTime, PreviousHorizontalVelocity);
		LandingTime = Time::GetGameTimeSeconds() + FlightTime;
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);

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

		/*UpdateInputDuration(RealTimeDeltaSeconds);
		if (NoInputDuration <= CameraInputDelay)	
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}*/

		UpdateLandingLocation();

		// System::DrawDebugPoint(LandingLocation, 10.f, FLinearColor::Red);
		// System::DrawDebugLine(Owner.ActorLocation, LandingLocation);

		FRotator DesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation()); 


		FRotator TargetRot = User.WorldToLocalRotation(GetTargetRotation());

		ChaseRotation.Value = DesiredRot; // This value is expected to be changed by outside systems		
		ChaseRotation.AccelerateTo(TargetRot, AccelerationDuration, DeltaTime);	
	
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
		
		// Yaw only for now
		DeltaRot.Roll = 0.f;
	 	
		// User.AddDesiredRotation(DeltaRot);
	}

	void UpdateLandingLocation()
	{
		float RemainingTime = LandingTime - Time::GetGameTimeSeconds();

		FVector HorizontalVelocity;
		float UpwardsSpeed = 0.f;

		GetSplitVelocity(MoveComp.Velocity, HorizontalVelocity, UpwardsSpeed);

		FVector DeltaHorizontalVelocity = HorizontalVelocity - PreviousHorizontalVelocity;
		PreviousHorizontalVelocity = HorizontalVelocity;

		LandingLocation += DeltaHorizontalVelocity * RemainingTime;
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (AxisInput.IsNearlyZero(0.001f))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.f;

		MovementDuration += DeltaTime;
	}

	FRotator GetTargetRotation()
	{
		FVector LookDirection = LandingLocation - PlayerUser.GetPlayerViewLocation();

		float PitchAngle = FMath::DegreesToRadians(5.f);
        FVector PitchAxis = FVector(0, 0, 1).CrossProduct(LookDirection).GetSafeNormal();
        FQuat RotateQuat(PitchAxis, PitchAngle);

		FVector PitchedLookDirection = RotateQuat.RotateVector(LookDirection);
		if (PitchedLookDirection.DotProduct(Owner.ActorForwardVector) <= 0)
		{
			PitchedLookDirection -= Owner.ActorForwardVector * PitchedLookDirection.DotProduct(Owner.ActorForwardVector);
			PitchedLookDirection += Owner.ActorForwardVector;
		}

		float YawAngle = FMath::DegreesToRadians(10.f);
        FVector YawAxis = FVector::UpVector;

		FQuat RotateQuatYawLeft(YawAxis, YawAngle);
		FQuat RotateQuatYawRight(YawAxis, -YawAngle);
		
		return RotateQuatYawLeft.RotateVector(PitchedLookDirection).Rotation(); 

		/*FVector YawedPitchDirectionLeft = RotateQuatYawLeft.RotateVector(PitchedLookDirection);
		FVector YawedPitchDirectionRight = RotateQuatYawRight.RotateVector(PitchedLookDirection);

		if (YawedPitchDirectionLeft.AngularDistance(PitchedLookDirection) < YawedPitchDirectionRight.AngularDistance(PitchedLookDirection))
			return YawedPitchDirectionLeft.Rotation(); 
		else
			return YawedPitchDirectionRight.Rotation(); */
		
	}

	bool GetLandingLocation(FVector StartingVelocity, float Gravity, FVector& OutLandingLocation, float& FlightTime, FVector& OutHorizontalVelocity)
	{
		float UpwardsSpeed = 0.f;
		GetSplitVelocity(StartingVelocity, OutHorizontalVelocity, UpwardsSpeed);

		if (UpwardsSpeed <= 0)
			return false;

		FlightTime = TimeOfFlight(Gravity, UpwardsSpeed);
		OutLandingLocation = Owner.ActorLocation + OutHorizontalVelocity * FlightTime;
		return true;
	}

	void GetSplitVelocity(FVector CurrentVelocity, FVector& OutHorizontalVelocity, float& OutUpwardsSpeed)
	{	
		FVector WorldUp = FVector::UpVector;

		if (MoveComp != nullptr)
			WorldUp = MoveComp.WorldUp;

		OutUpwardsSpeed = WorldUp.DotProduct(CurrentVelocity);
		OutHorizontalVelocity = CurrentVelocity - WorldUp * OutUpwardsSpeed;
	}

	float TimeOfFlight(float Gravity, float UpwardsSpeed)
	{
		if (UpwardsSpeed <= 0)
			return 0.f;		

		if (Gravity <= 0)
			return BIG_NUMBER;

		return 2.f * UpwardsSpeed / Gravity;
	}

	void RotateVector()
	{
		/*float Loc_Alpha = Math::Saturate(Alpha);
        float Angle = FMath::Acos(A.GetSafeNormal().DotProduct(B.GetSafeNormal()));
        FVector Axis = A.CrossProduct(B).GetSafeNormal();
        FQuat RotateQuat(Axis, Angle * Loc_Alpha);

        return RotateQuat.RotateVector(A);*/
	}
}