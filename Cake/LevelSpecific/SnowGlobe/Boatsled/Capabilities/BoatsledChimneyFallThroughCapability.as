import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Peanuts.Spline.SplineActor;

class UBoatsledChimneyFallThroughCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledChimneyFallThrough);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 65;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;

	ABoatsled Boatsled;
	UBoatsledComponent BoatsledComponent;

	UHazeSplineComponent TrajectorySpline;
	UHazeSplineComponent NextSplineTrack;
	UHazeSmoothSyncRotationComponent SmoothSteerInputRotation;

	FHazePointOfInterest PointOfInterest;
	UCameraShakeBase CameraShake;

	FHazeAcceleratedRotator AcceleratedBoatsledRotation;

	const float TerminalVelocity = 3600.f;

	float CharacterSpecificHorizontalCameraOffset = 1.f;
	float SmoothSteerInput = 0.f;

	bool bIsPreparedForLanding;
	bool bHasLanded;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
		SmoothSteerInputRotation = UHazeSmoothSyncRotationComponent::GetOrCreate(Owner, n"BoatsledChimneySmoothSteer");

		BoatsledComponent.BoatsledEventHandler.OnBoatsledFallingThroughChimney.AddUFunction(this, n"OnBoatsledFallingThroughChimney");

		if(PlayerOwner.IsMay())
			CharacterSpecificHorizontalCameraOffset = -1.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsFallingThroughChimney())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Init variables
		Boatsled = BoatsledComponent.Boatsled;
		SmoothSteerInputRotation.NumberOfSyncsPerSecond = 10;

		// Redirect velocity and turn off collisions
		Boatsled.MovementComponent.SetVelocity(-PlayerOwner.MovementWorldUp * Boatsled.MovementComponent.Velocity.Size());
		BoatsledComponent.SetBoatsledCollisionEnabled(false);

		// Calculate spline starting point and activate
		FHazeSplineSystemPosition SplinePosition = TrajectorySpline.GetPositionClosestToWorldLocation(Boatsled.ActorLocation, true);

		// Do camera junk
		PlayerOwner.ApplyCameraSettings(Boatsled.ChimneyFallthroughSpringArmSettings, 0.f, this);
		PlayerOwner.ApplyFieldOfView(120.f, 1.f, this);

		PointOfInterest.Blend = 0.5f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;

		// Detach player from boatsled
		PlayerOwner.DetachRootComponentFromParent();

		// Initialize camera accelerated rotator
		AcceleratedBoatsledRotation.SnapTo(Boatsled.ActorRotation);

		float DistanceAlongSpline = TrajectorySpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector SplineVector = TrajectorySpline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(SplineVector.Rotation(), 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boatsled.MovementComponent.CanCalculateMovement())
			return;

		FVector LocationOnSpline = TrajectorySpline.FindLocationClosestToWorldLocation(Boatsled.ActorLocation, ESplineCoordinateSpace::World);
		FVector LocationOffset = -Boatsled.MeshComponent.UpVector * 120.f;
		FVector TargetLocationOnSpline = LocationOnSpline + LocationOffset;

		float DistanceAlongSpline = TrajectorySpline.GetDistanceAlongSplineAtWorldLocation(LocationOnSpline);
		FVector BoatsledToSpline = TargetLocationOnSpline - Boatsled.ActorLocation;
		FVector SplineVector = TrajectorySpline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		// Create frame movement
		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledChimneyFallThrough");
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		bool bIsNearingEndOfSpline = IsNearingEndOfSpline(DistanceAlongSpline);

		if(HasControl())
		{
			// Just follow spline (for now)
			FVector Velocity = Boatsled.MovementComponent.GetVelocity();
			Velocity += SplineVector * Boatsled.MovementComponent.GravityMagnitude * DeltaTime;
			Velocity += BoatsledToSpline * DeltaTime * 10.f;

			// Check if boatsled is landing on next spline
			if(!bHasLanded && BoatsledIsLanding(DistanceAlongSpline))
			{
				FVector Redirect = (Velocity + Boatsled.MovementComponent.DownHit.Normal).GetSafeNormal();
				Velocity = Math::RotateVectorTowards(Velocity, Redirect, DeltaTime * 10.f);

				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"NextTrack", NextSplineTrack);
				Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnSetTrackAndNextState"), CrumbParams);

				bHasLanded = true;
			}

			MoveData.ApplyVelocity(Velocity.GetClampedToMaxSize(TerminalVelocity));

			// Handle rotation
			Boatsled.MovementComponent.SetTargetFacingDirection(SplineVector.GetSafeNormal());
			MoveData.ApplyTargetRotationDelta();

			// Go go go!
			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Check if the boatsled is reaching end of the spline
			if(!bIsPreparedForLanding && bIsNearingEndOfSpline)
				PrepareForLanding();
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			Boatsled.MovementComponent.Move(MoveData);
		}

		// Move player along with boatsled
		PlayerOwner.SetActorLocation(Boatsled.MeshComponent.GetSocketLocation(n"Totem"));
		PlayerOwner.SetActorRotation(Boatsled.MeshComponent.WorldRotation);

		// Rotate player- and boatsled's mesh offset
		RotateMeshOffset(SplineVector, DistanceAlongSpline, DeltaTime, bIsNearingEndOfSpline);

		// Apply camera offset 
		PlayerOwner.ApplyCameraOffset(Boatsled.ActorUpVector * 100.f + Boatsled.ActorForwardVector * 100.f * CharacterSpecificHorizontalCameraOffset, 1.f, this);

		// Apply point of interest; use next spline if we're almost done with this one
		if(bIsNearingEndOfSpline)
		{
			PointOfInterest.FocusTarget.WorldOffset = Boatsled.ActorLocation + Boatsled.MeshComponent.ForwardVector * 1000.f;
			PointOfInterest.Blend = 2.f;
		}
		else 
		{
			PointOfInterest.FocusTarget.WorldOffset = Boatsled.ActorLocation + SplineVector * 1000.f;
		}

		BoatsledComponent.RotateCameraRollOverTime(Boatsled.MeshComponent.UpVector, 2.f, DeltaTime);
		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

		// Shake dat bootie
		CameraShake = PlayerOwner.PlayCameraShake(Boatsled.CameraShake, 0.5f);

		// One locomotion, please
		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsFallingThroughChimney())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Re-enable collisions
		if(HasControl())
			BoatsledComponent.SetBoatsledCollisionEnabled(true);

		// Re-attach player to boatsled
		PlayerOwner.AttachToComponent(Boatsled.MeshComponent, n"Totem");

		// Clean camera stuff
		PlayerOwner.StopCameraShake(CameraShake);
		PlayerOwner.ClearCameraSettingsByInstigator(this, 2.f);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		// Slowly restore dat cam rotation
		BoatsledComponent.RestoreCameraRotation(6.f);

		// Cleanup shite
		Boatsled = nullptr;
		TrajectorySpline = nullptr;
		bIsPreparedForLanding = false;
		bHasLanded = false;
	}

	void RotateMeshOffset(const FVector& SplineVector, float DistanceAlongSpline, float DeltaTime, bool bIsNearingEndOfSpline)
	{
		// Start rotating towards next track's up vector once we're nearly done
		if(HasControl())
		{
			FVector LocationOnNextSpline = NextSplineTrack.FindLocationClosestToWorldLocation(Boatsled.ActorLocation, ESplineCoordinateSpace::World);
			float DistanceAlongNextSpline = NextSplineTrack.GetDistanceAlongSplineAtWorldLocation(LocationOnNextSpline) + 300.f;

			FVector NextSplineVector = NextSplineTrack.GetDirectionAtDistanceAlongSpline(DistanceAlongNextSpline, ESplineCoordinateSpace::World);
			FVector NextSplineUpVector = NextSplineTrack.GetUpVectorAtDistanceAlongSpline(DistanceAlongNextSpline, ESplineCoordinateSpace::World);

			if(bIsNearingEndOfSpline)
			{
				NextSplineUpVector += PlayerOwner.MovementWorldUp * 2.f;

				FRotator TargetRotation = Math::MakeRotFromXZ(NextSplineVector, NextSplineUpVector);
				AcceleratedBoatsledRotation.AccelerateTo(TargetRotation, 0.02f, DeltaTime);
				SmoothSteerInputRotation.Value = AcceleratedBoatsledRotation.Value;
			}
			else
			{
				// Handle input -player can only roll boatsled
				SmoothSteerInput = GetSteerInput(DeltaTime);

				float HorizontalInputAbs = FMath::Abs(SmoothSteerInput);
				float AcceleratedRoll = -FMath::Sign(SmoothSteerInput) * HorizontalInputAbs * DeltaTime * 2000.f;

				// Rotate based on input
				FQuat MeshOffsetQuat = FQuat(SplineVector, FMath::DegreesToRadians(AcceleratedRoll)) * Math::MakeQuatFromXZ(SplineVector, NextSplineUpVector);
				SmoothSteerInputRotation.Value = MeshOffsetQuat.Rotator();
			}
		}

		// Rotate mesh offset
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(SmoothSteerInputRotation.Value, 1.f);
	}

	// Get smooth steer input
	float GetSteerInput(float DeltaTime)
	{
		float HorizontalInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;
		if(HorizontalInput == 0.f)
		{
			if(!FMath::IsNearlyZero(SmoothSteerInput, 0.1f))
				return SmoothSteerInput + (DeltaTime * (SmoothSteerInput < 0.f ?  1.f : -1.f));
		}

		return FMath::Clamp(SmoothSteerInput + HorizontalInput * (Boatsled.AccelerationCurve.GetFloatValueNormalized(FMath::Abs(SmoothSteerInput)) + 1.5f) * 2.f * DeltaTime, -1.f, 1.f);
	}

	bool IsNearingEndOfSpline(float DistanceAlongSpline)
	{
		float CompletionRate = Math::Saturate(DistanceAlongSpline / TrajectorySpline.GetSplineLength());
		return CompletionRate > 0.75f;
	}

	bool BoatsledIsLanding(float DistanceAlongSpline)
	{
		return Boatsled.MovementComponent.DownHit.Actor == NextSplineTrack.Owner;
	}

	void PrepareForLanding()
	{
		bIsPreparedForLanding = true;

		// Re-enable collisions
		if(HasControl())
			BoatsledComponent.SetBoatsledCollisionEnabled(true);
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);

		PlayerOwner.BlockCapabilities(BoatsledTags::BoatsledMovement, this);
		PlayerOwner.BlockCapabilities(BoatsledTags::BoatsledBigAir, this);
		PlayerOwner.BlockCapabilities(BoatsledTags::BoatsledCamera, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);

		PlayerOwner.UnblockCapabilities(BoatsledTags::BoatsledMovement, this);
		PlayerOwner.UnblockCapabilities(BoatsledTags::BoatsledBigAir, this);
		PlayerOwner.UnblockCapabilities(BoatsledTags::BoatsledCamera, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledFallingThroughChimney(UHazeSplineComponent SplineComponent, UHazeSplineComponent SplineTrackAfterFallthrough)
	{
		TrajectorySpline = SplineComponent;
		NextSplineTrack = SplineTrackAfterFallthrough;
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnSetTrackAndNextState(FHazeDelegateCrumbData CrumbData)
	{
		UHazeSplineComponent NextTrack = Cast<UHazeSplineComponent>(CrumbData.GetObject(n"NextTrack"));
		BoatsledComponent.SetBoatsledTrack(NextTrack);
		BoatsledComponent.SetStateLocal(EBoatsledState::LandingAfterChimney);
	}
}