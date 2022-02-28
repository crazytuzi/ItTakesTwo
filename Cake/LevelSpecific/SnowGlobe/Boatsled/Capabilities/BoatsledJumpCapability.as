import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledMovementReplicationPrediction;

class UBoatsledJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledBigAir);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 62;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;
	ABoatsled Boatsled;

	UHazeSmoothSyncFloatComponent InputNetSync;
	FHazeAcceleratedFloat AcceleratedInput;

	FBoatsledJumpParams JumpParams;
	UCameraShakeBase CameraShake;

	FVector JumpVelocity;

	const float MaxInputRotation = 20.f;

	float JumpDuration;
	float ElapsedTime;

	bool bBoatsledIsAboutToLand;
	bool bBoatsledIsLanding;

	bool bRotateCamera;

	// Used for remote network prediction
	bool bRemoteIsResettingMeshOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
		InputNetSync = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"BoatsledJumpNetInputSync");

		BoatsledComponent.BoatsledEventHandler.OnBoatsledStartingJump.AddUFunction(this, n"OnBoatsledStartingJump");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsJumping())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		Boatsled = BoatsledComponent.Boatsled;
		ElapsedTime = 0.f;

		// This is used to keep height similar across different jumps regardless of the distance
		FVector LandingLocation = JumpParams.LandingLocation;
		float Ratio = 1.f - FMath::Abs(LandingLocation.Z - Boatsled.ActorLocation.Z) / Boatsled.ActorLocation.Distance(LandingLocation);

		// Calculate velocity to reach location
		JumpVelocity = CalculateVelocityForPathWithHeight(Boatsled.ActorLocation, LandingLocation, Boatsled.MovementComponent.GravityMagnitude, JumpParams.JumpHeight);
		Boatsled.MovementComponent.SetVelocity(JumpVelocity);
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(Math::MakeRotFromXZ(JumpVelocity, PlayerOwner.MovementWorldUp), 0.5f);

		// Get fly time
		JumpDuration = GetFlyTime(LandingLocation - Boatsled.ActorLocation, JumpParams.JumpHeight);

		// Update boatsled track spline to new one
		BoatsledComponent.TrackSpline = JumpParams.TrackSplineComponent;

		// Turn off boatsled collisions; turn on just before landing
		BoatsledComponent.SetBoatsledCollisionEnabled(false);

		// Do camera stuff
		PlayerOwner.ApplyPointOfInterest(JumpParams.JumpCameraSettings.PointOfInterest, this);
		PlayerOwner.ApplyCameraSettings(JumpParams.JumpCameraSettings.SpringArmSettings, 1.f, this);
		PlayerOwner.ApplyFieldOfView(JumpParams.JumpCameraSettings.FovValue, 2.f, this);

		// We need to rotate camera coming out of the tunnel just before the whale
		bRotateCamera = JumpParams.NextBoatsledState == EBoatsledState::WhaleSledding;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;

		if(HasControl())
		{
			// Wrap up if boatsled reached end of jump
			if(!bBoatsledIsLanding && ElapsedTime >= JumpDuration)
				LandBoatsled();

			if(bBoatsledIsLanding || !Boatsled.MovementComponent.CanCalculateMovement())
				return;

			// Check if we're almost done with jump
			if(!bBoatsledIsAboutToLand && ElapsedTime >= JumpDuration * 0.8f)
				PrepareForLanding();
		}

		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(BoatsledTags::BoatsledBigAir);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();
			Velocity += Boatsled.MovementComponent.GetGravity() * DeltaTime;
			MoveData.ApplyVelocity(Velocity);

			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());

			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Handle stick input
			InputNetSync.SetValue(AcceleratedInput.AccelerateTo(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X, 0.5f, DeltaTime));
		}
		else
		{
			// Consume crumb as usual
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);

			// Move mesh offset to location
			if(ActiveDuration < JumpDuration * 0.8f)
			{
				JumpVelocity += Boatsled.MovementComponent.GetGravity() * DeltaTime * 0.8f;
				FVector NextLocation = Boatsled.MeshOffsetComponent.WorldLocation + JumpVelocity * DeltaTime * 0.8f;
				Boatsled.MeshOffsetComponent.OffsetLocationWithTime(NextLocation, 0.f);
			}
			// Once we're almost there, start lerping back to crumb location
			else if(!bRemoteIsResettingMeshOffset)
			{
				bRemoteIsResettingMeshOffset = true;
				Boatsled.MeshOffsetComponent.ResetLocationWithTime(JumpDuration - ActiveDuration);
			}
		}

		// Allow player to fuck around a bit with rotation
		FRotator MeshOffsetRotation = Math::MakeRotFromXZ(Boatsled.MovementComponent.ActualVelocity, PlayerOwner.MovementWorldUp);
		if(ActiveDuration < JumpDuration * 0.82f)
			MeshOffsetRotation += FRotator(0.f, 0.f, InputNetSync.Value * MaxInputRotation);

		// Offset dat mesh
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(MeshOffsetRotation, 0.5f);

		// Request locomotion
		BoatsledComponent.RequestPlayerBoatsledLocomotion();

		// Play dat camera shake
		CameraShake = PlayerOwner.PlayCameraShake(JumpParams.JumpCameraSettings.CameraShakeClass, JumpParams.JumpCameraSettings.CameraShakeScale * 0.5f);

		// Slowly rotate camera roll to match sled's mesh's up vector
		if(bRotateCamera)
			BoatsledComponent.RotateCameraRollOverTime(Boatsled.MeshComponent.UpVector, 3.f, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsJumping())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Clear camera stuff
		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearCameraSettingsByInstigator(this, 1.f);
		PlayerOwner.ClearFieldOfViewByInstigator(this);
		PlayerOwner.StopCameraShake(CameraShake);

		// Reset camera roll in case we rotated
		if(bRotateCamera)
			BoatsledComponent.RestoreCameraRotation(2.f);

		if(HasControl())
			BoatsledComponent.SetBoatsledCollisionEnabled(true);
		else
			Boatsled.MeshOffsetComponent.ResetLocationWithTime(0.f);

		// Cleanup!
		Boatsled = nullptr;
		CameraShake = nullptr;
		ElapsedTime = 0.f;
		JumpDuration = 0.f;
		bBoatsledIsLanding = false;
		bBoatsledIsAboutToLand = false;
		bRotateCamera = false;
		bRemoteIsResettingMeshOffset = false;
	}

	// Stolen from TrajectoryStatics.as
	float GetFlyTime(FVector DistanceVector, float JumpHeight)
	{
		FVector HorizontalDirection;
		FVector VerticalDirection;
		float HorizontalDistance = 0.f;
		float VerticalDistance = 0.f;

		SplitVectorIntoVerticalHorizontal(DistanceVector, FVector::UpVector, VerticalDirection, VerticalDistance, HorizontalDirection, HorizontalDistance);

		float Gravity = Boatsled.MovementComponent.GravityMagnitude;
		float Velocity = FMath::Sqrt(2.f * JumpHeight * Gravity);

		float ValueToSqrt = (-2.f * VerticalDistance) / Gravity + ((Velocity / Gravity) * (Velocity / Gravity));
		return Velocity / Gravity + FMath::Sqrt(ValueToSqrt);
	}

	void PrepareForLanding()
	{
		if(HasControl())
			BoatsledComponent.SetBoatsledCollisionEnabled(true);

		PlayerOwner.ClearFieldOfViewByInstigator(this);
		bBoatsledIsAboutToLand = true;
	}

	void LandBoatsled()
	{
		// Communicate landing to boatsled component
		if(JumpParams.NextBoatsledState != EBoatsledState::ChimneyFallthrough)
			BoatsledComponent.BoatsledEventHandler.OnBoatsledLanding.Broadcast(Boatsled.MovementComponent.Velocity);

		// Set next boatsled state
		if(HasControl())
			BoatsledComponent.SetStateWithCrumb(JumpParams.NextBoatsledState);

		bBoatsledIsLanding = true;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);

		PlayerOwner.BlockCapabilities(CameraTags::Control, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);

		PlayerOwner.UnblockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledStartingJump(FBoatsledJumpParams BoatsledJumpParams)
	{
		JumpParams = BoatsledJumpParams;
	}
}