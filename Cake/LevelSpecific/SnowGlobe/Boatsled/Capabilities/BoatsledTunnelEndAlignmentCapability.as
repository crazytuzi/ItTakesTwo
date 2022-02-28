import Cake.LevelSpecific.SnowGlobe.Boatsled.Capabilities.BoatsledTunnelMovementCapabilityBase;

class UBoatsledTunnelEndAlignmentCapability : UBoatsledTunnelMovementCapabilityBase
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledTunnelEndAlignment);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 59;

	FVector TunnelEndLocation;

	float ElapsedAccelerationTime;
	float AccelerationDirection;
	float AlignmentTime;

	bool bIsAligned;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		// Set delegate
		BoatsledComponent.BoatsledEventHandler.OnBoatsledApproachingTunnelEnd.AddUFunction(this, n"OnBoatsledApproachingTunnelEnd");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsAligningBeforeTunnelEnd())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		Boatsled = BoatsledComponent.Boatsled;
		TrackSpline = BoatsledComponent.TrackSpline;

		// Find out which direction to accelerate to (right or left from boatsled)
		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector SplineUpVector = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		AccelerationDirection = BoatsledComponent.GetSplineRightVectorAdjustedToBoatsled().DotProduct(SplineUpVector) < 0.f ? 1.f : -1.f;

		// Do camera stuff
		PlayerOwner.ApplyCameraSettings(Boatsled.TunnelCameraSpringArmSettings, 2.f, this);

		// Get them precious vars
		float DistanceAtTunnelEnd = TrackSpline.GetDistanceAlongSplineAtWorldLocation(TunnelEndLocation);
		AlignmentTime = (DistanceAtTunnelEnd - DistanceAlongSpline) / Boatsled.MovementComponent.Velocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);

		FVector LocationOnSpline = TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineUpVector = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineVector = BoatsledComponent.GetSplineVector();

		float BoatsledDistanceToSpline = LocationOnSpline.Distance(Boatsled.ActorLocation);

		// We're only using the spline velocity here
		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledTunnelRepositioning");
		MoveData.OverrideCollisionWorldUp(Boatsled.MeshComponent.UpVector);
		MoveData.OverrideStepUpHeight(100.f);
		MoveData.OverrideStepDownHeight(1000.f);

		FVector GroundNormal;
		bool bIsGrounded = BoatsledComponent.GetGroundNormal(GroundNormal);

		if(HasControl())
		{
			FVector AutoSteer = FVector::ZeroVector;
			float BoatsledMeshRotationMultiplier = 0.3f;

			// Add spline velocity
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();
			Velocity += BoatsledComponent.GetSplineVelocity() * DeltaTime;

			if(!bIsGrounded)
			{
				Velocity += (LocationOnSpline - Boatsled.ActorLocation).GetSafeNormal() * DeltaTime * Boatsled.MovementComponent.GravityMagnitude;
			}
			// Auto steer if boatsled is not standing directly above guide spline
			else if(RequiresAutoSteering(SplineUpVector))
			{
				// Calculate auto steer vector
				AutoSteer = BoatsledComponent.GetSplineRightVectorAdjustedToBoatsled() * AccelerationDirection + SplineVector;

				// Compute acceleration based on distance from spline and velocity alignment
				float VelocityAlignment = 1.f - BoatsledComponent.SplineVector.DotProduct(Boatsled.MovementComponent.Velocity.GetSafeNormal());

				// Ease-in acceleration
				float AccelerationMultiplier = FMath::Square(Math::Saturate(ActiveDuration / 0.2f));
				AccelerationMultiplier *= FMath::Sqrt(BoatsledDistanceToSpline + Math::GetAngle(SplineUpVector, Boatsled.MeshComponent.UpVector)) * AlignmentTime * 2.f;

				// Add auto steer to velocity
				Velocity = Math::RotateVectorTowards(Velocity, AutoSteer, DeltaTime * AccelerationMultiplier);
			}
			// Accelerate towards tunnel end and guide spline
			else
			{
				BoatsledMeshRotationMultiplier = 0.1f;
				ElapsedAccelerationTime += DeltaTime;
				float AccelerationAlpha = Math::Saturate(ElapsedAccelerationTime / 0.2f);

				FVector BoatsledToGate = TunnelEndLocation - Boatsled.ActorLocation;
				AutoSteer = (LocationOnSpline - Boatsled.ActorLocation).GetSafeNormal() * (1.2f - AccelerationAlpha);

				// Ease-in acceleration
				float AccelerationMultiplier = FMath::Square(AccelerationAlpha);
				AccelerationMultiplier *= FMath::Sqrt(BoatsledDistanceToSpline * BoatsledToGate.Size());

				// Direct boatsled towards gate
				Velocity = Math::RotateVectorTowards(Velocity, BoatsledToGate.GetSafeNormal(), DeltaTime * AccelerationMultiplier);
			}

			// Rotate actor
			Boatsled.MovementComponent.SetTargetFacingDirection(Velocity.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Move!
			MoveData.ApplyVelocity(Velocity.GetClampedToMaxSize(BoatsledComponent.GetBoatsledMaxSpeed(false)));
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Tick boatsled offset rotation based on auto steered velocity- and ground normal vectors
			BoatsledComponent.UpdateNetBoatsledForwardRotation(AutoSteer, GroundNormal, 1.f, DeltaTime * BoatsledMeshRotationMultiplier);

			// Ready to rumble!
			BoatsledComponent.PlaySleddingForceFeedback();
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData,DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Offset dat mesh rotation
		OffsetBoatsledMeshRotation(BoatsledComponent.NetBoatsledForwardRotation.Value, GroundNormal, SplineUpVector, DistanceAlongSpline);

		// Override point of interest location
		BoatsledComponent.CameraLocationOfInterestOverride = Boatsled.ActorLocation + BoatsledComponent.GetSplineVector() * 500.f;

		// Rotate camera roll to match ground normal
		BoatsledComponent.RotateCameraRollOverTime(GroundNormal, 0.8f, DeltaTime);

		// Loco that motion
		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsAligningBeforeTunnelEnd())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Clear camera stuff
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		BoatsledComponent.RestoreCameraRotation(3.f);
		BoatsledComponent.RestoreCameraLocationOfInterest();

		// Cleanup
		TunnelEndLocation = FVector::ZeroVector;
		ElapsedAccelerationTime = 0.f;
		AccelerationDirection = 0.f;
		AlignmentTime = 0.f;
		bIsAligned = false;
	}
	
	bool RequiresAutoSteering(const FVector& SplineUpVector)
	{
		if(bIsAligned)
			return false;

		return Boatsled.MeshComponent.UpVector.DotProduct(SplineUpVector) < 0.92f;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledApproachingTunnelEnd(FVector GateLocation)
	{
		TunnelEndLocation = GateLocation;
	}
}