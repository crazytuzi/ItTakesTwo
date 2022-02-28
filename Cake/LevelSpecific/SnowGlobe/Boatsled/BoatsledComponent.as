import Cake.LevelSpecific.SnowGlobe.Boatsled.Boatsled;
import Peanuts.Outlines.Outlines;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Peanuts.Fades.FadeStatics;

#if EDITOR
import Rice.TemporalLog.TemporalLogStatics;
#endif

// Called by BoatsledActor on player interaction
void InitializeBoatsledComponent(ABoatsled BoatsledActor, AHazePlayerCharacter PlayerCharacter)
{
	UBoatsledComponent BoatsledComponent = UBoatsledComponent::GetOrCreate(PlayerCharacter);
	BoatsledComponent.Initialize(BoatsledActor);

#if EDITOR
	if(BoatsledActor.bSkipWaitAndPushStart)
	{
		// Attach to totem bone and add boatsled locomotion asset
		PlayerCharacter.AttachToComponent(BoatsledComponent.Boatsled.MeshComponent, n"Totem");
		PlayerCharacter.AddLocomotionAsset(BoatsledActor.GetLocomotionStateMachineAsset(PlayerCharacter), BoatsledComponent);
		BoatsledComponent.SetStateWithCrumb(BoatsledActor.StartState);
		BoatsledActor.MeshComponent.SetCollisionProfileName(n"NoCollision");
		BoatsledComponent.NetBoatsledForwardRotation.SetValue(BoatsledActor.ActorForwardVector);
		return;
	}

	StartTemporalLogging(BoatsledActor);
#endif

	BoatsledComponent.SetStateLocal(EBoatsledState::PlayerEnteringBoatsled);
}

const float PiBy2 = 3.1416f * 2.f;

class UBoatsledComponent : UActorComponent
{
	UPROPERTY()
	float SleddingBlendSpaceValue;

	UPROPERTY()
	float PushStartSpeedBlendSpaceValue;

	// Normalized horizontal direction value [-1, 1]
	UPROPERTY()
	float CollisionDirection;

	AHazePlayerCharacter PlayerOwner;

	ABoatsled Boatsled;
	UHazeSplineComponent TrackSpline;
	float TrackRadius = 500.f;

	APlayerMagnetActor PlayerMagnet;

	TArray<USceneComponent> BoatsledSkis;
	TArray<AActor> BoatsledTraceIgnores;

	// Used for synching mesh offset rotation
	UHazeSmoothSyncVectorComponent NetBoatsledForwardRotation;

	private EBoatsledState BoatsledState;

	UCameraUserComponent CameraUserComponent;
	FHazeAcceleratedRotator CameraYawAxisAcceleratedRotator;

	// Event handler component lives on boatsled
	UBoatsledEventComponent BoatsledEventHandler;

	FHazeMinMax FovRange;

	FVector PreviousNormal;

	const float BoatsledWeight = 2000.f;
	const float CollisionThreshold = 0.2f;

	private float FlexMaxSpeed;
	private float SteerSpeedHalf;

	FVector CameraLocationOfInterestOverride;
	float FlexSplineCameraOffset;

	float TunnelMovementAngleConstraint;

	float CameraResetTime;
	bool bMustResetCameraRotation;

	private bool bIsBoosting;
	private bool bIsDoubleBoosting;
	private bool bIsCrashing;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CameraUserComponent = UCameraUserComponent::Get(Owner);
		NetBoatsledForwardRotation = UHazeSmoothSyncVectorComponent::GetOrCreate(Owner, n"BoatsledForwardRotation");

		// Arbitrary fov range initialization
		FovRange.Min = 70.f;
		FovRange.Max = 100.f;
	}

	void Initialize(ABoatsled BoatsledActor)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		BlockCapabilities();

		Boatsled = BoatsledActor;
		Boatsled.SetControlSide(PlayerOwner);

		BoatsledEventHandler = UBoatsledEventComponent::Get(Boatsled);

		// Ignore collisions with player, other player and its boatsled
		Boatsled.MovementComponent.StartIgnoringActor(PlayerOwner);
		Boatsled.MovementComponent.StartIgnoringActor(Boatsled.OtherBoatsled);
		Boatsled.MovementComponent.StartIgnoringActor(PlayerOwner.OtherPlayer);

		// Transition them crumbs
		PlayerOwner.TriggerMovementTransition(this);

		// Add skis to array for usage convenience
		BoatsledSkis.Add(Boatsled.FrontLeftSki);
		BoatsledSkis.Add(Boatsled.FrontRightSki);
		BoatsledSkis.Add(Boatsled.RearLeftSki);
		BoatsledSkis.Add(Boatsled.RearRightSki);

		FlexMaxSpeed = Boatsled.MaxSpeed;
		SteerSpeedHalf = Boatsled.SteerSpeed * 0.5f;
		FlexSplineCameraOffset = Boatsled.SplinePointOfInterestDistanceFromBoatsled;

		ensure(BoatsledActor.BoatsledTrack != nullptr, "BoatsledActor - You forgot to set a reference to the track actor!");
		TrackSpline = UHazeSplineComponent::Get(Boatsled.BoatsledTrack, n"HazeGuideSpline");

		// Disable mesh outlines when player is in boatsled
		PlayerOwner.DisableOutlineByInstigator(this);
		PlayerOwner.OtherPlayer.DisableOutlineByInstigator(this);

		// Ignore boatsled-magnetMesh collisions and remove outline
		UMagneticPlayerComponent MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		if(MagneticPlayerComponent != nullptr)
		{
			PlayerMagnet = MagneticPlayerComponent.PlayerMagnet;
			if(PlayerMagnet != nullptr)
			{
				RemoveMeshFromPlayerOutline(PlayerMagnet.MagnetMesh, this);
				Boatsled.MovementComponent.StartIgnoringActor(PlayerMagnet);
			}
		}

		// Clear flags
		BoatsledState = EBoatsledState::None;

		// Setup them delegates
		BoatsledEventHandler.OnBoatsledStartingJump.AddUFunction(this, n"OnBoatsledStartingJump");
		BoatsledEventHandler.OnBoatsledBoost.AddUFunction(this, n"OnBoatsledBoost");
		BoatsledEventHandler.OnBoatsledApproachingTunnelEnd.AddUFunction(this, n"OnBoatsledApproachingTunnelEnd");
		BoatsledEventHandler.OnBoatsledLanding.AddUFunction(this, n"OnBoatsledLanding");

		// Initialize trace ignore actors
		BoatsledTraceIgnores.Add(PlayerOwner);
		BoatsledTraceIgnores.Add(PlayerOwner.OtherPlayer);
		BoatsledTraceIgnores.Add(Boatsled);
		BoatsledTraceIgnores.Add(Boatsled.OtherBoatsled);

		// Turn off collisions for remote side
		SetBoatsledCollisionEnabled(HasControl());

		// Block camera synchronization
		PlayerOwner.BlockCameraSyncronization(this);

		// Finally add boatsled capability sheet
		PlayerOwner.AddCapabilitySheet(Boatsled.BoatsledCapabilitySheet, EHazeCapabilitySheetPriority::High, this);

		// Add fix for last part in boatsled when locally setting yaw axis whilst using point of interest
		UCameraUserSettings::SetbApplyRollToDesiredRotation(PlayerOwner, true, this);
	}

	UFUNCTION()
	void StopSledding(bool bShouldFireStopEvents = true)
	{
		UnblockCapabilities();

		// Detach player from boatsled
		PlayerOwner.DetachRootComponentFromParent();

		// Clean locomotion asset
		PlayerOwner.ClearLocomotionAssetByInstigator(this);

		// Re-enable outlines
		PlayerOwner.EnableOutlineByInstigator(this);
		PlayerOwner.OtherPlayer.EnableOutlineByInstigator(this);

		// Re-enable collisions between boatsled and player actor
		Boatsled.MovementComponent.StopIgnoringActor(PlayerOwner);

		// Fire stop event if needed!
		if(bShouldFireStopEvents)
			BoatsledEventHandler.OnPlayerStoppedSledding.Broadcast(PlayerOwner);

		// Clean stuff
		BoatsledState = EBoatsledState::None;
		Boatsled.CleanAfterUse();

		// Remove capability sheet
		PlayerOwner.RemoveCapabilitySheet(Boatsled.BoatsledCapabilitySheet, this);

		// Restore camera syncronization
		PlayerOwner.UnblockCameraSyncronization(this);

		// Clear hacky camera stuff
		PlayerOwner.ClearSettingsByInstigator(this);
	}

	void SetBoatsledMaxSpeed(float MaxSpeed)
	{
		FlexMaxSpeed = FMath::Max(0.f, MaxSpeed);
	}

	float GetBoatsledMaxSpeed(bool bNeedsRubberBanding)
	{
		return FlexMaxSpeed * (bNeedsRubberBanding ? Boatsled.RubberbandBoostMultiplier : 1.f);
	}

	EBoatsledState GetBoatsledState() const
	{
		return BoatsledState;
	}

	void SetStateLocal(EBoatsledState NextState)
	{
		BoatsledState = NextState;
		PreviousNormal = FVector::ZeroVector;
	}

	void SetStateWithCrumb(EBoatsledState NextState)
	{
		if(!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"NextState", NextState);
		Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"OnSetStateCrumb"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSetStateCrumb(const FHazeDelegateCrumbData& CrumbData)
	{
		SetStateLocal(EBoatsledState(CrumbData.GetValue(n"NextState")));
	}

	bool GetGroundNormal(FVector& OutAverageNormal)
	{
		if(Boatsled == nullptr)
		 	return false;

		OutAverageNormal = FVector::ZeroVector;

		FHitResult HitResult;
		TArray<AActor> IgnoredTraceActors;
		IgnoredTraceActors.Add(PlayerOwner);
		IgnoredTraceActors.Add(PlayerOwner.OtherPlayer);
		IgnoredTraceActors.Add(Boatsled);
		IgnoredTraceActors.Add(Boatsled.OtherBoatsled);

		FVector NormalSum;
		FVector MovementComponentNormal = Boatsled.MovementComponent.DownHit.Normal;
		if(MovementComponentNormal != FVector::ZeroVector)
			NormalSum += MovementComponentNormal;

		// Gotta trace and get normals from all four skis
		for(USceneComponent Ski : BoatsledSkis)
		{
			System::LineTraceSingle(Ski.GetWorldLocation(), Ski.GetWorldLocation() - Boatsled.MeshComponent.UpVector * 100.f, ETraceTypeQuery::TraceTypeQuery2, false, IgnoredTraceActors, EDrawDebugTrace::None, HitResult, true);

			// if(HitResult.Actor != TrackSpline.Owner)
			// Eman TODO: Perform some sort of testing to check for ground actors only
			if(HitResult.bBlockingHit && !HitResult.Actor.IsA(ABoatsled::StaticClass()))
				NormalSum += HitResult.Normal;
		}

		if(NormalSum.IsZero())
			return false;

		OutAverageNormal = (NormalSum + PreviousNormal).GetSafeNormal();
		PreviousNormal = OutAverageNormal;

		// System::DrawDebugArrow(Boatsled.GetActorLocation(), Boatsled.GetActorLocation() + OutAverageNormal * 300, 100, FLinearColor::Green);

		return true;
	}

	void UpdateNetBoatsledForwardRotation(const FVector& InputVector, const FVector& UpVector, float SplineAlignmentMultiplier, float DeltaTime)
	{
		// Constrain boatsled velocity-based rotation to ground normal plane
		// Increase rotation speed based on how far apart the next rotation is
		// Finally, slerp rotation towards target 
		NetBoatsledForwardRotation.Value = NetBoatsledForwardRotation.Value.ConstrainToPlane(UpVector).GetSafeNormal();
		float AngularDistanceMultiplier = (Math::Saturate(NetBoatsledForwardRotation.Value.AngularDistance(InputVector) / PiBy2) + 0.05f) * Boatsled.MovementComponent.Velocity.Size() / SteerSpeedHalf * 0.5f;
		NetBoatsledForwardRotation.Value = Math::SlerpVectorTowards(NetBoatsledForwardRotation.Value, InputVector + GetSplineVector() * SplineAlignmentMultiplier, DeltaTime * AngularDistanceMultiplier);
	}

	void RotateBoatsledMeshOffsetToSlope(FVector Velocity, FVector GroundNormal, float OffsetRotationDelay = 0.08f)
	{
		if(TrackSpline == nullptr)
			return;

		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.GetActorLocation());

		FVector SplineUp = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector Guideline = (TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) + SplineUp * TrackRadius) - Boatsled.ActorLocation;

		FQuat Rotation = Math::MakeQuatFromXZ(Velocity.GetSafeNormal(), (GroundNormal + Guideline).GetSafeNormal());
		Boatsled.MeshOffsetComponent.OffsetRotationWithTime(Rotation.Rotator(), OffsetRotationDelay);
	}

	void RotateCameraRollToBoatlsedMeshUpVector(float DeltaTime)
	{
		if(TrackSpline == nullptr)
			return;

		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector SplineUp = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		float WorldUpDotMeshUp = SplineUp.DotProduct(Boatsled.MeshComponent.UpVector);

		float CurveValue = Boatsled.TunnelCameraYawCurve.GetFloatValue(WorldUpDotMeshUp);
		FVector CameraYawAxis = Math::SlerpVectorTowards(SplineUp, Boatsled.MeshComponent.UpVector, CurveValue);

		CameraYawAxis = CameraYawAxisAcceleratedRotator.AccelerateTo(CameraYawAxis.Rotation(), 2.f, DeltaTime).Vector();
		CameraUserComponent.SetYawAxis(CameraYawAxis);
	}

	// Eman TODO: Move to its own capability along with
	// BoatsledCameraRotationReset capability
	void RotateCameraRollOverTime(FVector UpVector, float RotationTime, float DeltaTime)
	{
		FVector CameraRotation = CameraYawAxisAcceleratedRotator.AccelerateTo(UpVector.Rotation(), RotationTime, DeltaTime).Vector();

		if(!FMath::IsNearlyEqual(CameraUserComponent.YawAxis.DotProduct(UpVector), 1.f - SMALL_NUMBER))
		{
			FVector PlaneNormal = CameraUserComponent.YawAxis.CrossProduct(UpVector).GetSafeNormal();
			PlaneNormal = Math::ConstrainVectorToPlane(UpVector, PlaneNormal);
			CameraRotation.ConstrainToPlane(PlaneNormal);
		}

		CameraUserComponent.SetYawAxis(CameraRotation);
	}

	// Used for tunnel movement (duh)
	float GetTunnelRadius(const FVector& LocationOnSpline, const FVector& SplineUpVector) const
	{
		float DepenetrationOffset = 200.f;
		return Internal_GetTunnelRadius(LocationOnSpline, SplineUpVector, DepenetrationOffset);
	}

	const float DepenetrationIncrement = 100.f;
	private float Internal_GetTunnelRadius(const FVector& LocationOnSpline, const FVector& SplineUpVector, float& DepenetrationOffset) const
	{
		TArray<FHitResult> HitResults;

		FVector TraceStart = LocationOnSpline + DepenetrationOffset;
		FVector TraceEnd = LocationOnSpline + SplineUpVector * 2000.f + DepenetrationOffset;

		if(System::LineTraceMulti(TraceStart, TraceEnd, ETraceTypeQuery::TraceTypeQuery1, false, BoatsledTraceIgnores, EDrawDebugTrace::None, HitResults, true))
		{
			for(FHitResult HitResult : HitResults)
			{
				if(!HitResult.bBlockingHit)
					continue;

				if(HitResult.Actor != TrackSpline.Owner)
					continue;

				if(HitResult.bStartPenetrating)
				{
					DepenetrationOffset += DepenetrationIncrement;
					return (Internal_GetTunnelRadius(LocationOnSpline, SplineUpVector, DepenetrationOffset) + DepenetrationOffset) * 0.5f;
				}

				return (HitResult.Distance + DepenetrationOffset) * 0.5f;
			}
		}

		return 750.f;
	}

	void ConsumeMovementCrumb(FHazeFrameMovement& MoveData, const float& DeltaTime)
	{
		FHazeActorReplicationFinalized CrumbData;
		Boatsled.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
		MoveData.ApplyConsumedCrumbData(CrumbData);
	}

	bool IsCollidingWithBarrier(FVector& OutCollisionLocation, FVector& OutCollisionNormal, bool bDebugDrawCollision = false)
	{
		FVector TraceOrigin = Boatsled.ActorLocation + Boatsled.MeshComponent.UpVector * 30.f;

		float DirectionMultiplier = 1.f;
		TArray<FHitResult> HitResults;

		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(Boatsled.MovementComponent);
		TraceParams.IgnoreActors(BoatsledTraceIgnores);
		TraceParams.TraceShape = FCollisionShape::MakeBox(FVector(100.f, 15.f, 15.f));
		TraceParams.UnmarkToTraceWithOriginOffset();

		TraceParams.ShapeRotation = Boatsled.MeshComponent.GetWorldRotation().Quaternion();
		TraceParams.From = TraceOrigin;

		if(bDebugDrawCollision)
			TraceParams.DebugDrawTime = 0.f;

		// Trace from both sides
		for(int i = 0; i < 2; i++)
		{
			TraceParams.To = TraceOrigin + Boatsled.MeshComponent.GetRightVector() * 80.f * DirectionMultiplier;
			
			// Sweep for overlaps with collision shape
			if(TraceParams.OverlapSweep(HitResults))
			{
				for(FHitResult HitResult : HitResults)
				{
					if(HitResult.Component == nullptr)
						continue;

					if(HitResult.Component.HasTag(BoatsledTags::BoatsledCollisionBarrierActorTag))
					{
						OutCollisionLocation = HitResult.ImpactPoint;
						OutCollisionNormal = HitResult.Normal;

						if(bDebugDrawCollision)
							System::DrawDebugArrow(HitResult.ImpactPoint, HitResult.ImpactPoint + HitResult.Normal * 1000.f, 10.f, FLinearColor::Green);

						return true;
					}
				}
			}

			DirectionMultiplier *= -1.f;
		}

		return false;
	}

	bool HandleCollisionWithOtherBoatsled(FVector& OutVelocity, float DeltaTime)
	{
		FHazeHitResult HitResult;
		if(!Boatsled.PlayerCollisionCapsule.SweepTrace(Boatsled.PlayerCollisionCapsule.WorldLocation, Boatsled.PlayerCollisionCapsule.WorldLocation + OutVelocity * DeltaTime * 2.f, HitResult, -1.f))
			return false;

		FVector CollisionNormal = HitResult.Normal;

		// Bend bounce to the sides if hit is coming from forward/behind
		if(FMath::Abs(CollisionNormal.DotProduct(Boatsled.ActorForwardVector)) > 0.9f)
			CollisionNormal = CollisionNormal.ConstrainToPlane(Boatsled.ActorForwardVector);

		// Notify of collision; use barrier collision stuff for now
		float CollisionForce = OutVelocity.ConstrainToDirection(CollisionNormal).Size() / GetBoatsledMaxSpeed(NeedsRubberBanding());
		BoatsledHitBarrier(HitResult.ImpactPoint, CollisionNormal, CollisionForce);

		// Rotate current frame's velocity toward impact normal
		OutVelocity = Math::SlerpVectorTowards(OutVelocity, CollisionNormal, DeltaTime);
		return true;
	}

	void RestoreFlexSplineCameraOffset()
	{
		FlexSplineCameraOffset = Boatsled.SplinePointOfInterestDistanceFromBoatsled;
	}

	void RestoreCameraLocationOfInterest()
	{
		CameraLocationOfInterestOverride = FVector::ZeroVector;
	}

	void RestoreCameraRotation(float ResetTime = 1.f)
	{
		bMustResetCameraRotation = true;
		CameraResetTime = ResetTime;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBoatsledBoost()
	{
		if(bIsBoosting)
		{
			bIsDoubleBoosting = true;
			System::SetTimer(this, n"ClearDoubleBoost", 0.1f, false);
		}
		else
		{
			bIsBoosting = true;
		}

		PlayBoostForceFeedback();
	}

	void StopBoosting()
	{
		bIsBoosting = false;
		bIsDoubleBoosting = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void ClearDoubleBoost()
	{
		bIsDoubleBoosting = false;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerEnteringBoatsled()
	{
		return BoatsledState == EBoatsledState::PlayerEnteringBoatsled;
	}

	UFUNCTION(BlueprintPure)
	bool IsWaitingForOtherPlayer()
	{
		return BoatsledState == EBoatsledState::WaitingForOtherPlayer;
	}

	UFUNCTION(BlueprintPure)
	bool IsWaitingForStartLight()
	{
		return BoatsledState == EBoatsledState::WaitingForStartLight;
	}

	UFUNCTION(BlueprintPure)
	bool IsPushingSled()
	{
		return BoatsledState == EBoatsledState::PushStart;
	}

	// Any kind of sledding but jumping
	UFUNCTION(BlueprintPure)
	bool IsSledding()
	{
		return BoatsledState == EBoatsledState::HalfPipeSledding || 
			   BoatsledState == EBoatsledState::TunnelSledding ||
			   BoatsledState == EBoatsledState::WhaleSledding ||
			   BoatsledState == EBoatsledState::TunnelEndAlignment ||
			   BoatsledState == EBoatsledState::LandingAfterChimney;
	}

	UFUNCTION(BlueprintPure)
	bool IsSleddingOnHalfPipe()
	{
		return BoatsledState == EBoatsledState::HalfPipeSledding;
	}

	UFUNCTION(BlueprintPure)
	bool IsSleddingOnTunnel()
	{
		return BoatsledState == EBoatsledState::TunnelSledding;
	}

	UFUNCTION(BlueprintPure)
	bool IsAligningBeforeTunnelEnd()
	{
		return BoatsledState == EBoatsledState::TunnelEndAlignment;
	}

	UFUNCTION(BlueprintPure)
	bool IsJumping()
	{
		return BoatsledState == EBoatsledState::Jumping;
	}

	UFUNCTION(BlueprintPure)
	bool IsBoosting()
	{
		return bIsBoosting;
	}

	UFUNCTION(BlueprintPure)
	bool IsDoubleBoosting()
	{
		return bIsDoubleBoosting;
	}

	UFUNCTION(BlueprintPure)
	bool IsWhaleSledding()
	{
		return BoatsledState == EBoatsledState::WhaleSledding;
	}

	UFUNCTION(BlueprintPure)
	bool IsFallingThroughChimney()
	{
		return BoatsledState == EBoatsledState::ChimneyFallthrough;
	}

	UFUNCTION(BlueprintPure)
	bool IsLandingAfterChimneyFallthrough()
	{
		return BoatsledState == EBoatsledState::LandingAfterChimney;
	}

	UFUNCTION(BlueprintPure)
	bool IsCrashing()
	{
		return bIsCrashing;
	}

	UFUNCTION(BlueprintPure)
	bool IsFinishing()
	{
		return BoatsledState == EBoatsledState::Finish;
	}

	bool NeedsRubberBanding()
	{
		if(TrackSpline == nullptr)
			return false;

		if(Boatsled == nullptr)
			return false;

		if(!Boatsled.bRubberBandingEnabled)
			return false;

		if(Boatsled.OtherBoatsled == nullptr)
			return false;

		float DistanceOnSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		float OtherPlayerDistanceOnSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.OtherBoatsled.ActorLocation);

		if(DistanceOnSpline > OtherPlayerDistanceOnSpline)
			return false;

		float DistanceBetweenSleds = FMath::Abs(DistanceOnSpline - OtherPlayerDistanceOnSpline);
		if(DistanceBetweenSleds < 1000.f)
			return false;

		return DistanceBetweenSleds > Boatsled.MaxRubberbandDistance;
	}

	float GetDistanceBetweenBoatsleds()
	{
		float DistanceOnSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		float OtherPlayerDistanceOnSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.OtherBoatsled.ActorLocation);

		return FMath::Abs(DistanceOnSpline - OtherPlayerDistanceOnSpline);
	}

	FVector GetSlopeDirection(FVector GroundNormal, FVector WorldUpOverride = FVector::ZeroVector)
	{
		FVector UpVector = WorldUpOverride.IsZero() ? PlayerOwner.GetMovementWorldUp() : WorldUpOverride;
		FVector BiNormal = GroundNormal.CrossProduct(UpVector);
		return GroundNormal.CrossProduct(BiNormal).GetSafeNormal();
	}

	FVector GetSlopeVelocity(FVector GroundNormal, FVector WorldUpOverride = FVector::ZeroVector)
	{
		FVector SlopeVector = GetSlopeDirection(GroundNormal, WorldUpOverride);
		return SlopeVector * Boatsled.MovementComponent.GetGravityMagnitude() * SlopeVector.DotProduct(-PlayerOwner.MovementWorldUp) * Math::Saturate(1.f - SlopeVector.DotProduct(Boatsled.MovementComponent.Velocity.GetSafeNormal()));
	}

	FVector GetSplineVector() property
	{
		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.GetActorLocation());
		return TrackSpline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
	}

	FVector GetSplineVelocity() property
	{
		FVector DirOnSpline = GetSplineVector();
		return DirOnSpline * Boatsled.MovementComponent.GetGravityMagnitude() /** DirOnSpline.DotProduct(-PlayerOwner.MovementWorldUp)*/;
	}

	FVector GetAdjustedSplineVelocity(float ForwardOffset)
	{
		float OffsetDistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.GetActorLocation() + GetSplineVector() * ForwardOffset);
		FVector DirOnSpline = (TrackSpline.GetLocationAtDistanceAlongSpline(OffsetDistanceAlongSpline, ESplineCoordinateSpace::World) - Boatsled.GetActorLocation()).GetSafeNormal();

		FVector VelocityOnSpline = DirOnSpline * Boatsled.MovementComponent.GetGravityMagnitude();
		FVector Normal, Tangent;
		Math::DecomposeVector(Normal, Tangent, VelocityOnSpline, Boatsled.MeshComponent.RightVector);

		// Scale down horizontal component to eliminate shitty auto-steering
		// VelocityOnSpline -= Normal * 0.5f;
		return VelocityOnSpline;
	}

	// Gets the right vector of the spline transported to boatsled
	FVector GetSplineRightVectorAdjustedToBoatsled() property
	{
		return -GetSplineVector().CrossProduct(Boatsled.MeshComponent.UpVector).GetSafeNormal();
	}

	// Returns normalized boatsled speed relative to its max speed (range [0, 1])
	UFUNCTION(BlueprintPure)
	float GetNormalizedSpeed() property
	{
		if(Boatsled == nullptr)
			return 0.f;

		return Math::Saturate(Boatsled.MovementComponent.Velocity.Size() / Boatsled.MaxSpeed);
	}

	void RequestPlayerBoatsledLocomotion()
	{
		if(!PlayerOwner.Mesh.CanRequestLocomotion())
		{
			Print("BoatsledComponent::RequestPlayerBoatsledLocomotion() - Cannot request locomotion this frame!");
			return;
		}

		FHazeRequestLocomotionData LocomotionRequest;
		LocomotionRequest.AnimationTag = BoatsledTags::AnimationRequestTag;
		PlayerOwner.RequestLocomotion(LocomotionRequest);
	}

	void ChangeMaxSpeedOverTime(float TargetSpeed, float Time)
	{
		PlayerOwner.SetCapabilityAttributeValue(BoatsledTags::BoatsledSpeedModeratorDelta, TargetSpeed - FlexMaxSpeed);
		PlayerOwner.SetCapabilityAttributeValue(BoatsledTags::BoatsledSpeedModeratorTime, Time);

		PlayerOwner.SetCapabilityActionState(BoatsledTags::BoatsledSpeedModeratorActionState, EHazeActionState::ActiveForOneFrame);
	}

	void PlaySleddingForceFeedback(float Scale = 1.f)
	{
		float RumbleNoise = FMath::Abs(FMath::PerlinNoise1D(Boatsled.ActorLocation.X));
		PlayerOwner.SetFrameForceFeedback(RumbleNoise * 0.02f * Scale, 0.012f * Scale);
	}

	void PlayCollisionForceFeedback()
	{
		PlayerOwner.PlayForceFeedback(Boatsled.CollisionRumble, false, false, n"BoatsledCollision");
	}

	void PlayBoostForceFeedback()
	{
		PlayerOwner.PlayForceFeedback(Boatsled.CollisionRumble, false, false, n"BoatsledBoost", 0.38f);
	}

	void PlayLandingForceFeedback()
	{
		PlayerOwner.PlayForceFeedback(Boatsled.LandingRumble, false, false, n"BoatsledLanding");
	}

	void PlayJumpStartForceFeedback()
	{
		PlayerOwner.PlayForceFeedback(Boatsled.JumpStartRumble, false, false, n"BoatsledJumpStart", 0.27f);
	}

	UFUNCTION()
	float GetBoatsledAngle() property
	{
		return Boatsled.MeshComponent.GetWorldRotation().Roll;
	}

	void SetBoatsledTrack(UHazeSplineComponent SplineComponent) property
	{
		TrackSpline = SplineComponent;
		Boatsled.BoatsledTrack = SplineComponent == nullptr ? nullptr : Cast<AHazeActor>(TrackSpline.Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledStartingJump(FBoatsledJumpParams BoatsledJumpParams)
	{
		SetStateLocal(EBoatsledState::Jumping);
		SetBoatsledTrack(BoatsledJumpParams.TrackSplineComponent);

		Boatsled.OnBoatsledJumped(Boatsled.MovementComponent.GetVelocity());

		PlayJumpStartForceFeedback();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledLanding(FVector LandingVelocity)
	{
		Boatsled.OnBoatsledLanded(Boatsled.MovementComponent.GetVelocity());
		PlayLandingForceFeedback();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledApproachingTunnelEnd(FVector TunnelEndLocation)
	{
		// Change state
		SetStateLocal(EBoatsledState::TunnelEndAlignment);

		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		FVector LocationOnSpline = TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineUpVector = TrackSpline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		// Find tunnel centre
		Boatsled.SmoothTunnelPivotLocation.Value = LocationOnSpline + SplineUpVector * GetTunnelRadius(LocationOnSpline, SplineUpVector);

		// Get rotation based on boatlsed's current location
		FVector BoatsledToPivot = (Boatsled.SmoothTunnelPivotLocation.Value - Boatsled.ActorLocation).GetSafeNormal();
		float PivotRoll = -FMath::RadiansToDegrees(BoatsledToPivot.AngularDistanceForNormals(SplineUpVector));
		Boatsled.SmoothTunnelPivotRotation.Value = FRotator(SplineVector.ToOrientationRotator().Pitch, SplineVector.ToOrientationRotator().Yaw, PivotRoll);
	}

	void SetBoatsledCollisionEnabled(bool bIsEnabled)
	{
		if(Boatsled == nullptr)
			return;

		if(bIsEnabled && !HasControl())
		{
			Warning("Hands-off buddy! Remote shall not enable collisions, ever!");
			return;
		}

		Boatsled.SphereCollider.SetCollisionProfileName(bIsEnabled ? Boatsled.CollisionProfile : n"NoCollision");
	}

	void BoatsledHitBarrier(const FVector& CollisionLocation, const FVector& CollisionNormal, float NormalizedCollisionForce)
	{
		// Don't leave crumb if boatsled is still mid-collision;
		// test also against collision force
		if(NormalizedCollisionForce > CollisionThreshold)
		{
			// Play collision rumble
			PlayCollisionForceFeedback();
			PlayerOwner.SetCapabilityAttributeValue(n"BoatSledImpactAudio", NormalizedCollisionForce);

			// Only send animation info if we're done colliding
			if(!bIsCrashing)
				LeaveCollisionDelegateCrumb(CollisionLocation, CollisionNormal);
		}
	}

	private void LeaveCollisionDelegateCrumb(const FVector& CollisionLocation, const FVector& CollisionNormal)
	{
		float NormalizedDirection = -CollisionNormal.DotProduct(Boatsled.MeshComponent.RightVector);

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"NormalizedDirection", NormalizedDirection);
		CrumbParams.AddVector(n"CollisionLocation", CollisionLocation);

		Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"OnBoatsledCollision_Crumb"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledCollision_Crumb(const FHazeDelegateCrumbData& CrumbData)
	{
		bIsCrashing = true;
		CollisionDirection = CrumbData.GetValue(n"NormalizedDirection");
	}

	void ClearBoatsledCollision()
	{
		bIsCrashing = false;
		CollisionDirection = 0.f;
	}

	float GetFramePredictionLag() const
	{
		return Network::HasWorldControl() ? Boatsled.CrumbComponent.PredictionLag : Boatsled.CrumbComponent.PredictionLag * 2.f;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(n"IceSkating", this);
		PlayerOwner.BlockCapabilities(n"CanDie", this);

		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(n"IceSkating", this);
		PlayerOwner.UnblockCapabilities(n"CanDie", this);

		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
	}
}
