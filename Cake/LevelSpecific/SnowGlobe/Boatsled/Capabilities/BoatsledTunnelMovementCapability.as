import Cake.LevelSpecific.SnowGlobe.Boatsled.Capabilities.BoatsledTunnelMovementCapabilityBase;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledMovementReplicationPrediction;

class UBoatsledTunnelMovementCapability : UBoatsledTunnelMovementCapabilityBase
{
	default CapabilityTags.Add(BoatsledTags::BoatsledTunnelMovement);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 63;

	const float CameraSettingsBlendTime = 3.f;

	float SmoothSteerInput;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsSleddingOnTunnel())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Override walkable slope angle
		UMovementSettings::SetWalkableSlopeAngle(Boatsled, 80.f, this);

		// Do camera stuff
		PlayerOwner.ApplyCameraSettings(Boatsled.TunnelCameraSpringArmSettings, CameraSettingsBlendTime, this);

		// Set point of interest camera z offset
		BoatsledComponent.FlexSplineCameraOffset = 3000.f;

		// Initialize camera accelerated rotator
		BoatsledComponent.CameraYawAxisAcceleratedRotator.SnapTo(BoatsledComponent.CameraUserComponent.GetBaseRotation().UpVector.ToOrientationRotator());

		// Initialize forward direction to match boatsled's forward vector
		BoatsledComponent.NetBoatsledForwardRotation.Value = Boatsled.MeshComponent.ForwardVector;

		// Redirect previous jump's velocity towards spline vector
		FVector StartVelocity = BoatsledComponent.GetSplineVector() * Boatsled.MovementComponent.Velocity.Size();
		Boatsled.MovementComponent.SetVelocity(StartVelocity);

		// Turn on headlights
		Boatsled.ToggleHeadlamp(true);

		// Add UBoatsledMovementReplicationPrediction as custom crumb world calculator and add custom params to crumbs
		float DistanceAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector TunnelCenterLocation = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) + BoatsledComponent.TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) * BoatsledComponent.TrackRadius;
		Boatsled.CrumbComponent.MakeCrumbsUseCustomWorldCalculator(UBoatsledMovementReplicationPrediction::StaticClass(), this);
		Boatsled.CrumbComponent.IncludeCustomParamsInActorReplication(Boatsled.MovementComponent.Velocity, (TunnelCenterLocation - Boatsled.ActorLocation).Rotation(), this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledTunnelMovement");
		MoveData.OverrideCollisionWorldUp(Boatsled.MeshComponent.UpVector);
		MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);
		MoveData.OverrideStepUpHeight(100.f);
		MoveData.OverrideStepDownHeight(1000.f);

		FVector GroundNormal;
		bool bIsGrounded = BoatsledComponent.GetGroundNormal(GroundNormal);

		float DistanceAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector SplineUpVector = BoatsledComponent.TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector TunnelCentre = GetTunnelCentre(SplineUpVector, DistanceAlongSpline);

		if(HasControl())
		{
			// Get raw velocity
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();

			// Add spline- and slope velocities
			Velocity += BoatsledComponent.GetSplineVelocity() * DeltaTime;

			// Get input relative to the point on the spline where the boatsled lies
			// Then rotate velocity towards input vector
			float LandingInputMultiplier = FMath::Square(FMath::Min(ActiveDuration, 1.f)); // Used to smooth-in handling after landing
			float HorizontalInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X * LandingInputMultiplier;
			FVector InputVector = (BoatsledComponent.GetSplineRightVectorAdjustedToBoatsled() * HorizontalInput) + BoatsledComponent.GetSplineVector();
			Velocity = Math::RotateVectorTowards(Velocity, InputVector, DeltaTime * Boatsled.SteerSpeed * 0.8f);

			// Calculate slope velocity and rotate previous velocity
			float SlopeMultiplier = 1.2f - Velocity.GetSafeNormal().DotProduct(InputVector);
			Velocity = Math::RotateVectorTowards(Velocity, BoatsledComponent.GetSlopeDirection(GroundNormal, SplineUpVector), DeltaTime * Boatsled.SteerSpeed * SlopeMultiplier);

			// Bounce velocity if colliding with other player's boatsled
			if(BoatsledComponent.HandleCollisionWithOtherBoatsled(Velocity, DeltaTime))
			{
				// Change mesh offset vector to reflect collision
				// Eman TODO: Get animation or make this fancier
			 	InputVector = BoatsledComponent.GetSplineVector();
			}

			// Tick boatsled offset rotation based on input- and ground normal vectors
			BoatsledComponent.UpdateNetBoatsledForwardRotation(InputVector, GroundNormal, 1.2f, DeltaTime * 0.3);

			// Handle the banding of the rub
			bool bNeedsRubberBanding = BoatsledComponent.NeedsRubberBanding();
			if(bIsGrounded && bNeedsRubberBanding)
				Velocity *= Boatsled.RubberbandBoostMultiplier;

			// Clamp dat vector
			Velocity = Velocity.GetClampedToMaxSize(BoatsledComponent.GetBoatsledMaxSpeed(bNeedsRubberBanding));

			// Rotate boatsled actor and mesh
			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Move!
			MoveData.ApplyVelocity(Velocity);
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Feed by back with haptism!
			BoatsledComponent.PlaySleddingForceFeedback();
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Override point of interest location
		BoatsledComponent.CameraLocationOfInterestOverride = Boatsled.ActorLocation + BoatsledComponent.GetSplineVector() * 500.f + Boatsled.MeshComponent.UpVector * 350.f;

		// Rotate boatsled mesh offset
		OffsetBoatsledMeshRotation(BoatsledComponent.NetBoatsledForwardRotation.Value, GroundNormal, SplineUpVector, DistanceAlongSpline);

		// Get sweet locomotion
		BoatsledComponent.RequestPlayerBoatsledLocomotion();

		// (Locally) Rotate camera's roll after we're done blending in camera settings
		float RollTime = ActiveDuration > (CameraSettingsBlendTime + 0.2f) ? 0.8f : ( CameraSettingsBlendTime - ActiveDuration);
		BoatsledComponent.RotateCameraRollOverTime(Boatsled.MeshComponent.UpVector, RollTime, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsSleddingOnTunnel())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Clear walkable angle setting
		UMovementSettings::ClearWalkableSlopeAngle(Boatsled, this);

		// Clear camera stuff
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		BoatsledComponent.RestoreCameraLocationOfInterest();

		// Clear point of interest offset
		BoatsledComponent.RestoreFlexSplineCameraOffset();

		// Cleanup
		Boatsled = nullptr;
		TrackSpline = nullptr;
		SmoothSteerInput = 0.f;

		// Remove custom world calculator
		BoatsledComponent.Boatsled.CrumbComponent.RemoveCustomWorldCalculator(this);
		BoatsledComponent.Boatsled.CrumbComponent.RemoveCustomParamsFromActorReplication(this);
	}
}