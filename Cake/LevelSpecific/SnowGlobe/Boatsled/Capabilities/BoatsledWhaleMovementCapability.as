import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Vino.Movement.MovementSettings;

class UBoatsledWhaleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledWhaleMovement);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 63;

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	ABoatsled Boatsled;

	UHazeSplineComponent SideSpline_Left;
	UHazeSplineComponent SideSpline_Right;

	FHazeAcceleratedVector SlopeAccelerator;
	FHazeAcceleratedVector InputAccelerator;
	FHazeAcceleratedVector CameraInputOffsetAccelerator;

	// No code is good without arbitrary bullshite
	const float Uks = 0.4f;

	bool bIsRampingUp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsWhaleSledding())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();
	
		Boatsled = BoatsledComponent.Boatsled;

		// Store boundary splines references
		SideSpline_Left = UHazeSplineComponent::Get(BoatsledComponent.TrackSpline.Owner, n"WhaleSplineBoundary_Left");
		SideSpline_Right = UHazeSplineComponent::Get(BoatsledComponent.TrackSpline.Owner, n"WhaleSplineBoundary_Right");

		// Increase boatsled max speed
		BoatsledComponent.SetBoatsledMaxSpeed(Boatsled.MaxSpeed * 1.12f);

		// Ease-in movement after landing
		Boatsled.MovementComponent.SetVelocity(Boatsled.MovementComponent.GetVelocity() + BoatsledComponent.GetSplineVelocity());

		// Fire event
		Boatsled.BoatsledEventHandler.OnBoatsledWhaleSleddingStarted.Broadcast();

		// Initialize boatsled rotation offset component accelerator
		FVector UpVector = BoatsledComponent.TrackSpline.GetUpVectorAtDistanceAlongSpline(BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation), ESplineCoordinateSpace::World);
		BoatsledComponent.UpdateNetBoatsledForwardRotation(FVector::ZeroVector, UpVector, 0.5f, Time::GlobalWorldDeltaSeconds * 0.2f);

		// Initialize input accelerator
		InputAccelerator.SnapTo(FVector::ZeroVector);

		// Apply them settings of the camera
		PlayerOwner.ApplyCameraSettings(Boatsled.CameraSpringArmSettings, 2.f, this);

		// Turn on headlights
		Boatsled.ToggleHeadlamp(true);

		// Subscribe to ramp up event
		Boatsled.BoatsledEventHandler.OnBoatsledWhaleRampUp.AddUFunction(this, n"OnFinalRampUpStretch");

		// Add whale movement replication prediction to crumbs
		Boatsled.CrumbComponent.MakeCrumbsUseCustomWorldCalculator(UBoatsledWhaleMovementReplicationPrediction::StaticClass(), this);
		Boatsled.CrumbComponent.IncludeCustomParamsInActorReplication(Boatsled.MovementComponent.Velocity, Boatsled.MeshComponent.WorldRotation, this, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledMovement");
		MoveData.OverrideStepUpHeight(50.f);
		MoveData.OverrideStepDownHeight(1000.f);
		MoveData.OverrideCollisionWorldUp(Boatsled.MeshComponent.UpVector);

		// Get ground normal
		FVector GroundNormal;
		bool bIsGrounded = BoatsledComponent.GetGroundNormal(GroundNormal);

		if(HasControl())
		{
			float SplineDotWorldUp = BoatsledComponent.GetSplineVector().DotProduct(PlayerOwner.MovementWorldUp);
			bool bSplineIsAimingUpwards = SplineDotWorldUp >= -0.02f;

			// Get stuff!
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();
			bool bNeedsRubberBanding = BoatsledComponent.NeedsRubberBanding();
			float HorizontalInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;
			float DistanceAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.GetActorLocation());
			FVector SplineUpVector = BoatsledComponent.TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

			// Add spline velocity
			Velocity += BoatsledComponent.GetSplineVelocity() * DeltaTime * (bSplineIsAimingUpwards ? 1.f : 0.5f);

			// Get input relative to absolute right at spline point; add spline vector to reduce horizontal amount
			// Reduce input if boatsled is already moving in that general direction
			// Finally, rotate velocity towards input vector
			FVector RawInputVector = (BoatsledComponent.GetSplineRightVectorAdjustedToBoatsled() * HorizontalInput) + BoatsledComponent.GetSplineVector();
			FVector AcceleratedInputVector = InputAccelerator.AccelerateTo(RawInputVector, 0.7f, DeltaTime);
			float InputMultiplier = (1.5f - Velocity.GetSafeNormal().DotProduct(AcceleratedInputVector.GetSafeNormal())) * (bIsRampingUp ? 0.2f : 1.2f);
			Velocity = Math::RotateVectorTowards(Velocity, AcceleratedInputVector, DeltaTime * Boatsled.SteerSpeed * InputMultiplier);

			// Don't care for slope and friction when we're ramping up, just center boatsled
			if(bIsRampingUp)
			{
				FVector BoatsledToSplineCenterAhead = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline + 1000.f, ESplineCoordinateSpace::World) - Boatsled.ActorLocation;
				Velocity = Math::RotateVectorTowards(Velocity, BoatsledToSplineCenterAhead, FMath::Sqrt(BoatsledToSplineCenterAhead.Size()) * DeltaTime);
			}
			else
			{
				// Add slope velocity
				FVector SlopeVector = BoatsledComponent.GetSlopeDirection(GroundNormal, bSplineIsAimingUpwards ? Boatsled.MeshComponent.UpVector : PlayerOwner.MovementWorldUp);
				float SlopeMultiplier = 1.5f - Velocity.GetSafeNormal().DotProduct(AcceleratedInputVector);
				Velocity = Math::RotateVectorTowards(Velocity, SlopeVector, DeltaTime * Boatsled.SteerSpeed * SlopeMultiplier);

				// Add friction to das mixen, ja; reduce it when we're using turbo
				float FrameUks = BoatsledComponent.IsBoosting() ? 0.05f : Uks;
				FVector Friction = -Velocity.GetSafeNormal() * FrameUks * BoatsledComponent.BoatsledWeight * (FrameUks + 1.f - Velocity.GetSafeNormal().DotProduct(BoatsledComponent.GetSlopeDirection(GroundNormal)));
				Velocity += Friction * DeltaTime;

				// Add a little bit of camera offset when player is steering
				FVector	LocationOfInterest = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline + 3000.f, ESplineCoordinateSpace::World);
				LocationOfInterest += Boatsled.ActorForwardVector * 3000.f - Boatsled.ActorUpVector * 2000.f;
				BoatsledComponent.CameraLocationOfInterestOverride = LocationOfInterest;
			}

			// Bounce velocity if colliding with other player's boatsled
			if(BoatsledComponent.HandleCollisionWithOtherBoatsled(Velocity, DeltaTime))
			{
				// Change mesh offset vector to reflect collision
				// Eman TODO: Get animation or make this fancier
			 	RawInputVector = BoatsledComponent.GetSplineVector();
			}

			// Tick boatsled offset rotation based on input- and ground normal vectors
			BoatsledComponent.UpdateNetBoatsledForwardRotation(RawInputVector, GroundNormal, bIsRampingUp ? 10.f : 0.5f, DeltaTime * 0.2f);

			// Push down on boatsled
			Velocity -= Boatsled.MeshComponent.UpVector * Boatsled.MovementComponent.GravityMagnitude * DeltaTime;

			// Handle rubber banding
			if(bIsGrounded && bNeedsRubberBanding)
				Velocity *= Boatsled.RubberbandBoostMultiplier;

			// Clamp velocity
			Velocity = Velocity.GetClampedToMaxSize(BoatsledComponent.GetBoatsledMaxSpeed(bNeedsRubberBanding) + (bIsRampingUp ? 200.f : 0.f));

			// Rotate boatsled actor to face velocity
			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Apply velocity and move
			MoveData.ApplyVelocity(ConstrainVelocityToSpline(Velocity, DistanceAlongSpline, DeltaTime));
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Feed by back with haptism!
			BoatsledComponent.PlaySleddingForceFeedback(2.f);
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Offset boatsled rotation
		FQuat Rotation = Math::MakeQuatFromXZ(BoatsledComponent.NetBoatsledForwardRotation.Value, GroundNormal);
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(Rotation.Rotator(), 0.08f);

		// Request locomotion
		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsWhaleSledding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		Boatsled.OnWhaleSleddingFinished();
		Boatsled.BoatsledEventHandler.OnBoatsledWhaleRampUp.Unbind(this, n"OnFinalRampUpStretch");

		PlayerOwner.ClearCameraSettingsByInstigator(this);
		BoatsledComponent.RestoreCameraLocationOfInterest();

		bIsRampingUp = false;

		// Remove replication prediction
		Boatsled.CrumbComponent.RemoveCustomWorldCalculator(this);
		Boatsled.CrumbComponent.RemoveCustomParamsFromActorReplication(this);
	}

	FVector ConstrainVelocityToSpline(FVector VelocityDelta, const float DistanceAlongSpline, const float DeltaTime)
	{
		// Setup some useful vars
		FVector LocationOnSpline = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToBoatsled = Boatsled.ActorLocation - LocationOnSpline;
		FVector SplineRightVector = BoatsledComponent.TrackSpline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		// Determine which spline component to use as boundary depending on which side of the og. spline the boatsled is at
		// Get location info from spline
		float DistanceAlongSideSpline;
		FVector LocationOnSideSpline;
		UHazeSplineComponent SideSplineComponent = SplineRightVector.DotProduct(SplineToBoatsled) > 0.f ? SideSpline_Right : SideSpline_Left;
		SideSplineComponent.FindDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation, LocationOnSideSpline, DistanceAlongSideSpline);

		// Project spline locations to boatsled normal plane
		LocationOnSpline = LocationOnSpline.PointPlaneProject(Boatsled.ActorLocation, Boatsled.MeshComponent.UpVector);
		LocationOnSideSpline = LocationOnSideSpline.PointPlaneProject(Boatsled.ActorLocation, Boatsled.MeshComponent.UpVector);
		FVector BoatsledToSideSpline = (LocationOnSideSpline - Boatsled.ActorLocation).GetSafeNormal();
		FVector BoatsledToSpline = (LocationOnSpline - Boatsled.ActorLocation).GetSafeNormal();

		// Calculate how close boatsled is from boundary
		float BoatsledSplineAlpha = 1.f - Math::Saturate(Boatsled.ActorLocation.Distance(LocationOnSideSpline) / LocationOnSpline.Distance(LocationOnSideSpline));

		// Get velocity component in direction towards boundary and reduce velocity towards boundary
		float SpeedTowardsBoundary = VelocityDelta.Size() * Math::Saturate(VelocityDelta.GetSafeNormal().DotProduct(BoatsledToSideSpline));
		FVector BoundaryBand = -BoatsledToSideSpline * SpeedTowardsBoundary * FMath::Pow(BoatsledSplineAlpha, 4.f);
		
		// Add boundary banding to velocity delta
		FVector ConstrainedVelocity = VelocityDelta + BoundaryBand;

		// Now enforce boatsled staying within the boundaries
		// Rotate velocity towards spline if boatsled's next position lies outside bounds
		FVector NextBoatsledLocation = Boatsled.ActorLocation + ConstrainedVelocity * DeltaTime;
		FVector NextBoatsledToSpline = LocationOnSpline - NextBoatsledLocation;
		FVector NextBoatsledToSideSpline = LocationOnSideSpline - NextBoatsledLocation;
		if(NextBoatsledToSpline.Size() > LocationOnSpline.Distance(LocationOnSideSpline))
			ConstrainedVelocity = Math::RotateVectorTowards(ConstrainedVelocity, NextBoatsledToSpline.GetSafeNormal(), DeltaTime * Boatsled.SteerSpeed + FMath::Sqrt(NextBoatsledToSideSpline.Size() * 0.2f));

		return ConstrainedVelocity;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFinalRampUpStretch()
	{
		bIsRampingUp = true;
		BoatsledComponent.RestoreCameraLocationOfInterest();
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
	}
}

class UBoatsledWhaleMovementReplicationPrediction : UHazeReplicationLocationCalculator
{
	ABoatsled Boatsled;
	UHazeCrumbComponent CrumbComponent;
	UBoatsledComponent BoatsledComponent;

	UHazeSplineComponent WhaleSpline;
	UHazeSplineComponent BarrierSpline_Left;
	UHazeSplineComponent BarrierSpline_Right;

	TArray<AActor> TraceIgnores;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent RelativeComponent)
	{
		Boatsled = Cast<ABoatsled>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Boatsled.CurrentBoatsledder);

		// Get whale splines
		WhaleSpline = BoatsledComponent.TrackSpline;
		BarrierSpline_Left = UHazeSplineComponent::Get(WhaleSpline.Owner, n"WhaleSplineBoundary_Left");
		BarrierSpline_Right = UHazeSplineComponent::Get(WhaleSpline.Owner, n"WhaleSplineBoundary_Right");

		// Fill trace ignore array
		TraceIgnores.Add(Boatsled);
		TraceIgnores.Add(Boatsled.CurrentBoatsledder);

		if(Boatsled.OtherBoatsled != nullptr)
		{
			TraceIgnores.Add(Boatsled.OtherBoatsled);
			TraceIgnores.Add(Boatsled.OtherBoatsled.CurrentBoatsledder);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.CustomCrumbVector = Boatsled.MovementComponent.Velocity;
		OutTargetParams.CustomCrumbRotator = Boatsled.MeshComponent.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		float ControlDistanceAlongSpline = WhaleSpline.GetDistanceAlongSplineAtWorldLocation(TargetParams.Location);
		FVector ControlLocationOnSpline = WhaleSpline.GetLocationAtDistanceAlongSpline(ControlDistanceAlongSpline, ESplineCoordinateSpace::World);

		// Choose whale barrier spline (left or right) depending on proximity
		FVector SplineRightVector = WhaleSpline.GetRightVectorAtDistanceAlongSpline(ControlDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToBoatsled = (TargetParams.Location - ControlLocationOnSpline).GetSafeNormal();
		UHazeSplineComponent BarrierSpline = SplineToBoatsled.DotProduct(SplineRightVector) > 0.f ? BarrierSpline_Right : BarrierSpline_Left;

		// Get location on barrier spline
		float ControlDistanceAlongBarrierSpline = BarrierSpline.GetDistanceAlongSplineAtWorldLocation(TargetParams.Location);
		FVector ControlLocationOnBarrierSpline = BarrierSpline.GetLocationAtDistanceAlongSpline(ControlDistanceAlongBarrierSpline, ESplineCoordinateSpace::World);

		// Project spline locations to same boatsled normal plane
		ControlLocationOnSpline = ControlLocationOnSpline.PointPlaneProject(TargetParams.Location, Boatsled.MeshComponent.UpVector);
		ControlLocationOnBarrierSpline = ControlLocationOnBarrierSpline.PointPlaneProject(TargetParams.Location, Boatsled.MeshComponent.UpVector);

		// Get Boatsled->BarrierSpline alpha
		float ControlBoatsledHorizontalAlpha = Math::Saturate(TargetParams.Location.Distance(ControlLocationOnSpline) / ControlLocationOnSpline.Distance(ControlLocationOnBarrierSpline));

		// Now let's get predicted distances along splines based on frame latency
		float PredictionOffset = TargetParams.CustomCrumbVector.Size() * BoatsledComponent.GetFramePredictionLag();
		float PredictedDistanceAlongSpline = ControlDistanceAlongSpline + PredictionOffset;
		float PredictedDistanceAlongBarrierSpline = ControlDistanceAlongBarrierSpline + PredictionOffset;

		// Get spline locations
		FVector PredictedLocationOnSpline = WhaleSpline.GetLocationAtDistanceAlongSpline(PredictedDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector PredictedLocationOnBarrierSpline = BarrierSpline.GetLocationAtDistanceAlongSpline(PredictedDistanceAlongBarrierSpline, ESplineCoordinateSpace::World);

		// Get raw predicted location based on boatsled horizontal alpha
		FVector PredictedLocation = FMath::Lerp(PredictedLocationOnSpline, PredictedLocationOnBarrierSpline, ControlBoatsledHorizontalAlpha);

		FHitResult HitResult;
		if(System::LineTraceSingle(PredictedLocation + Boatsled.MovementWorldUp * 500.f, PredictedLocation - Boatsled.MovementWorldUp * 520.f, ETraceTypeQuery::TraceTypeQuery1, false, TraceIgnores, EDrawDebugTrace::None, HitResult, true))
			PredictedLocation = HitResult.Location;

		TargetParams.CustomLocation = PredictedLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		// Disregard crumbs that come without prediction info; use stock instead
		if(!TargetParams.CustomLocation.IsZero())
			TargetParams.Location = TargetParams.CustomLocation;
	}
}