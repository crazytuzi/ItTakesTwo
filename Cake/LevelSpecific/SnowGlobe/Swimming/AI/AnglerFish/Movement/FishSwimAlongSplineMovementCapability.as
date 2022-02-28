import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Vino.Movement.SplineLock.SplineLockComponent;

class UFishSwimAlongSplineMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Swimming");
	default CapabilityTags.Add(n"SplineSwimming");
	//default CapabilityTags.Add(CapabilityTags::Movement); // If it has the movement tag it'll be deactivated when teleporting :P

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 15.f;

    UFishBehaviourComponent BehaviourComp;
	UHazeSplineComponent Spline = nullptr;
	FName DefaultCollisionProfile = n"WaspNPC";

	USplineLockComponent SplineLockComp;

	FHazeAcceleratedRotator Rotation;

	bool bCaptured = false;
	float CaptureRadius = 1000.f;
	FHazeAcceleratedVector CaptureOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UFishBehaviourComponent::Get(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComp.MovingAlongSpline == nullptr)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// TODO: Should deactivate locally when done following the crumbs instead
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (BehaviourComp.MovingAlongSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// MovingAlongSpline and other control parameters are set by behaviour
		// on both control and remote side, but it seems we can desynced for one frame (probably)
		OutParams.AddObject(n"Spline", BehaviourComp.MovingAlongSpline);
		OutParams.AddNumber(n"SnapToSpline", BehaviourComp.bSnapToMoveSpline ? 1 : 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Spline = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"Spline")); 
		ensure(Spline != nullptr);

		bCaptured = (ActivationParams.GetNumber(n"SnapToSpline") != 0);
		if (bCaptured)
		{
			SetMutuallyExclusive(n"Swimming", true); 

			// Disable collision while swimming along spline
			DisableCollision();

			// Teleport to spline
			FVector StartLoc = Spline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
			FRotator StartRot = Spline.GetRotationAtSplinePoint(0.f, ESplineCoordinateSpace::World);
			Owner.TeleportActor(StartLoc, StartRot);
			BehaviourComp.DistanceAlongMoveSpline = 0.f;
			Rotation.SnapTo(StartRot);
			CaptureOffset.SnapTo(FVector::ZeroVector);
		}

		FConstraintSettings FishConstrainSettings;
		FishConstrainSettings.ConstrainType = EConstrainCollisionHandlingType::FullConstrain;
		FishConstrainSettings.SplineToLockMovementTo = Spline;

		SplineLockComp.LockOwnerToSpline(FishConstrainSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bCaptured)
			SetMutuallyExclusive(n"Swimming", false);

		// Return to normal collision
		UShapeComponent CollisionComp = MoveComp.CollisionShapeComponent;
		CollisionComp.SetCollisionProfileName(DefaultCollisionProfile); 

		SplineLockComp.StopLocking();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
        float Acceleration = BehaviourComp.MovementAcceleration;
        if (Acceleration < 0.f)
            Acceleration = 0.f;  

		// We keep track of approximate distance along spline ourselves for now, 
		float DistAlongSpline = BehaviourComp.DistanceAlongMoveSpline;
		FVector SplineLoc = Spline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
		FVector OwnLoc = Owner.GetActorLocation();
		if (!CheckCapture(SplineLoc, DeltaSeconds))
		{
			// Move towards spline until close enough to blend in to it
			BehaviourComp.MoveTo(SplineLoc, BehaviourComp.MovementAcceleration, 10.f);
			return;
		}

        // Accelerate along spline with friction 
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"FishSwimming");
		CaptureOffset.AccelerateTo(FVector::ZeroVector,  3.f, DeltaSeconds);

		// Apply rotation locally
		FVector Direction = Spline.GetTangentAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
		Direction.Normalize();
		if (!BehaviourComp.bMoveAlongSplineForwards)
			Direction = -Direction;
		Rotation.Value = Owner.ActorRotation;			
		Rotation.AccelerateTo(Direction.Rotation(), 10.f, DeltaSeconds);
		MoveComp.SetTargetFacingRotation(Rotation.Value); 
		MoveData.ApplyTargetRotationDelta();

		if (HasControl())
		{
			float Speed = (BehaviourComp.bMoveAlongSplineForwards ? Acceleration : -Acceleration);
			float NewDist = BehaviourComp.DistanceAlongMoveSpline + Speed * DeltaSeconds;
			FVector NewSplineLoc = Spline.GetLocationAtDistanceAlongSpline(NewDist, ESplineCoordinateSpace::World) + CaptureOffset.Value;
			FVector Delta = (NewSplineLoc - OwnLoc);
			MoveData.ApplyDelta(Delta);

			if (DeltaSeconds > 0.f)
				MoveComp.SetVelocity(Delta / DeltaSeconds);

			// We expect behaviours to set spline and acceleration each tick
			BehaviourComp.MovingAlongSpline = nullptr;
			BehaviourComp.MovementAcceleration = 0.f;
			BehaviourComp.DistanceAlongMoveSpline = NewDist;
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			FVector Delta = ConsumedParams.GetDeltaTranslation();
			MoveData.ApplyDelta(Delta);

			// On remote we set this to the closest location rather than the wanted location, should be good enough
			BehaviourComp.DistanceAlongMoveSpline = Spline.GetDistanceAlongSplineAtWorldLocation(OwnLoc + Delta);
		}

		// Change world up so we'll move up/down properly
		Owner.ChangeActorWorldUp(GetSwimmingWorldUp(Rotation.Value));

		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, FeatureName::Swimming);
		CrumbComp.LeaveMovementCrumb();

#if EDITOR
		// Spline.bHazeEditorOnlyDebugBool = true;
		if (Spline.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSpline(Spline, FLinearColor::Yellow);
#endif
	}

	void DisableCollision()
	{
		// This will stop Fish overlapping triggers, fix if necessary
		UShapeComponent CollisionComp = MoveComp.CollisionShapeComponent;
		// Since the haze movement relies on collision channel response we cannot set collsionenabled only 
		CollisionComp.SetCollisionProfileName(n"NoCollision"); 
	}

	bool CheckCapture(const FVector& EntryLoc, float DeltaSeconds)
	{
		if (bCaptured)
			return true;

		if (DeltaSeconds <= 0.f)
			return false;

		// Not captured yet, check if we're close enough to spline
		FVector ToSpline = EntryLoc - Owner.GetActorLocation();
		if (ToSpline.IsNearlyZero(CaptureRadius))
		{
			DisableCollision();
			bCaptured = true;

			FRotator PrevRot = MoveComp.PreviousOwnerRotation.Rotator();
			FRotator RotationalVelocity = FRotator::ZeroRotator;
			RotationalVelocity.Yaw = (Owner.GetActorRotation().Yaw - PrevRot.Yaw) / DeltaSeconds;
			RotationalVelocity.Pitch = (Owner.GetActorRotation().Pitch - PrevRot.Pitch) / DeltaSeconds;
			Rotation.SnapTo(Owner.GetActorRotation(), RotationalVelocity);

			CaptureOffset.SnapTo(-ToSpline, MoveComp.GetVelocity());
			SetMutuallyExclusive(n"Swimming", true); 
			return true;
		}

		return false;
	}

	FQuat FwdToUp = FQuat(FRotator(90.f, 0.f, 0.f));
	FVector GetSwimmingWorldUp(const FRotator& ForwardRot)
	{
		FRotator UpRot = FRotator(FQuat(ForwardRot) * FwdToUp);
		return UpRot.Vector();
	}
};
