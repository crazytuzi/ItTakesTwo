import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledLandingAfterChimneyCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 66;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	ABoatsled Boatsled;

	UBoatsledComponent BoatsledComponent;
	UHazeSplineComponent TrackSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BoatsledComponent.IsLandingAfterChimneyFallthrough())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Boatsled = BoatsledComponent.Boatsled;
		TrackSpline = BoatsledComponent.TrackSpline;

		// Add height offset to camera for it to not collide with the track's slope
		PlayerOwner.ApplyCameraSettings(Boatsled.TunnelCameraSpringArmSettings, 2.f, this);

		// Increase boatsled max speed
		BoatsledComponent.SetBoatsledMaxSpeed(Boatsled.MaxSpeed * 1.34f);

		// Carry chimney fallthrough momentum
		Boatsled.MovementComponent.SetVelocity(BoatsledComponent.GetSplineVelocity());
		Boatsled.MeshOffsetComponent.ResetRelativeLocationWithTime(0.f);

		// Fire 'ride almost done' event
		BoatsledComponent.BoatsledEventHandler.OnBoatsledRideAlmostOver.Broadcast();

		// Fire the landing event
		BoatsledComponent.BoatsledEventHandler.OnBoatsledLanding.Broadcast(Boatsled.MovementComponent.Velocity);

		// Set input block AS; will be used by the following movement capability
		PlayerOwner.SetCapabilityActionState(BoatsledTags::BoatsledInputBlock, EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledLandingAfterChimney");
		MoveData.OverrideStepUpHeight(100.f);
		MoveData.OverrideStepDownHeight(1000.f);

		FVector GroundNormal;
		BoatsledComponent.GetGroundNormal(GroundNormal);

		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector SplineUpVector = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		if(HasControl())
		{
			// Add spline velocity
			FVector Velocity = Boatsled.MovementComponent.ActualVelocity + BoatsledComponent.GetSplineVelocity() * DeltaTime;

			// Position boatsled over center track center
			FVector BoatsledToSplineCenter = TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) - Boatsled.ActorLocation;
			Velocity += BoatsledToSplineCenter.GetSafeNormal() * DeltaTime * Boatsled.SteerSpeed;

			// Set actor rotation
			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Move
			MoveData.ApplyVelocity(Velocity.GetClampedToMaxSize(BoatsledComponent.GetBoatsledMaxSpeed(false)));
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Blerum yo!
			BoatsledComponent.PlaySleddingForceFeedback();
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Handle boatsled mesh offset rotation
		FQuat MeshRotation = Math::MakeQuatFromXZ(Boatsled.MovementComponent.ActualVelocity, GroundNormal);
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(MeshRotation.Rotator(), 0.08f);
		
		// Move!
		BoatsledComponent.RequestPlayerBoatsledLocomotion();

		// Override location of interest
		FVector LocationOfInterest = TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline + 4000.f, ESplineCoordinateSpace::World) - SplineUpVector * 500.f;
		BoatsledComponent.CameraLocationOfInterestOverride = LocationOfInterest;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsLandingAfterChimneyFallthrough())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Clear camera shit
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		BoatsledComponent.RestoreCameraLocationOfInterest();
	}
}