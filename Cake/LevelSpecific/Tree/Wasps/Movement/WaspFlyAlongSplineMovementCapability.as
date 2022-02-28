import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Vino.Movement.SplineLock.SplineLockComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;

class UWaspFlyAlongSplineMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Flying");
	default CapabilityTags.Add(n"SplineFlying");
	//default CapabilityTags.Add(CapabilityTags::Movement); // If it has the movement tag it'll be deactivated when teleporting :P

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 15.f;

    UWaspBehaviourComponent BehaviourComp;
	UWaspMovementComponent WaspMoveComp;
	UHazeSplineComponent Spline = nullptr;
	FName DefaultCollisionProfile = n"WaspNPC";

	USplineLockComponent SplineLockComponent;

	FHazeAcceleratedRotator Rotation;

	bool bCaptured = false;
	float CaptureRadius = 200.f;
	FHazeAcceleratedVector CaptureOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		SplineLockComponent = USplineLockComponent::GetOrCreate(Owner);
		WaspMoveComp = Cast<UWaspMovementComponent>(MoveComp);
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
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		if (BehaviourComp.MovingAlongSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// MovingAlongSpline and other control parameters are set by behaviour
		// on both control and remote side.
		Spline = BehaviourComp.MovingAlongSpline;
		ensure(Spline != nullptr);

		bCaptured = false;
		if (BehaviourComp.bSnapToMoveSpline)
		{
			bCaptured = true;
			SetMutuallyExclusive(n"Flying", true); 

			// Disable collision while flying along spline
			DisableCollision();

			// Teleport to spline
			FVector StartLoc = GetLocationAlongSpline(0.f);
			FRotator StartRot = Spline.GetRotationAtSplinePoint(0.f, ESplineCoordinateSpace::World);
			Owner.TeleportActor(StartLoc, StartRot);
			BehaviourComp.DistanceAlongMoveSpline = 0.f;
			Rotation.SnapTo(StartRot);
			CaptureOffset.SnapTo(FVector::ZeroVector);
		}

		FConstraintSettings WaspConstraint;
		WaspConstraint.SplineToLockMovementTo = Spline;
		WaspConstraint.ConstrainType = EConstrainCollisionHandlingType::FullConstrain;

		SplineLockComponent.LockOwnerToSpline(WaspConstraint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bCaptured)
			SetMutuallyExclusive(n"Flying", false);

		// Return to normal collision
		UShapeComponent CollisionComp = MoveComp.CollisionShapeComponent;
		CollisionComp.SetCollisionProfileName(DefaultCollisionProfile); 

		SplineLockComponent.StopLocking();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
        float Acceleration = BehaviourComp.Acceleration;
        if (Acceleration < 0.f)
            Acceleration = 0.f;  

		// We keep track of approximate distance along spline ourselves for now, 
		float DistAlongSpline = BehaviourComp.DistanceAlongMoveSpline;
		FVector SplineLoc = GetLocationAlongSpline(DistAlongSpline);
		FVector OwnLoc = Owner.GetActorLocation();
		if (!CheckCapture(SplineLoc, DeltaSeconds))
		{
			// Move towards spline until close enough to blend in to it
			BehaviourComp.MoveTo(SplineLoc, BehaviourComp.Acceleration);
			return;
		}

        // Accelerate along spline with friction 
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WaspFlyingMovement");
		CaptureOffset.AccelerateTo(FVector::ZeroVector, 3.f, DeltaSeconds);

		// Apply rotation locally
		FVector Direction = Spline.GetTangentAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
		Direction.Normalize();
		if (!BehaviourComp.bMoveAlongSplineForwards)
			Direction = -Direction;
		FRotator TargetRot = Direction.Rotation();
		if (BehaviourComp.bHasFocus)
			TargetRot = (BehaviourComp.FocusLocation - Owner.GetActorLocation()).Rotation();
		Rotation.Value = Owner.ActorRotation;			
		Rotation.AccelerateTo(TargetRot, 1.f, DeltaSeconds);
		MoveComp.SetTargetFacingRotation(Rotation.Value); 
		MoveData.ApplyTargetRotationDelta();

		if (HasControl())
		{
			float Speed = (BehaviourComp.bMoveAlongSplineForwards ? Acceleration : -Acceleration);
			float NewDist = BehaviourComp.DistanceAlongMoveSpline + Speed * DeltaSeconds;
			FVector NewSplineLoc = GetLocationAlongSpline(NewDist) + CaptureOffset.Value;
			FVector Delta = (NewSplineLoc - OwnLoc);
			MoveData.ApplyDelta(Delta);

			if (DeltaSeconds > 0.f)
				MoveComp.SetVelocity(Delta / DeltaSeconds);

			// We expect behaviours to set spline and acceleration each tick
			BehaviourComp.MovingAlongSpline = nullptr;
			BehaviourComp.Acceleration = 0.f;
			BehaviourComp.DistanceAlongMoveSpline = NewDist;
		}
		else
		{
			// Remote, follow them crumbsies
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			FVector Delta = ConsumedParams.GetDeltaTranslation();
			MoveData.ApplyDelta(Delta);

			// On remote we set this to the closest location rather than the wanted location, should be good enough
			BehaviourComp.DistanceAlongMoveSpline = Spline.GetDistanceAlongSplineAtWorldLocation(OwnLoc + Delta);
		}

		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();

#if EDITOR
		// Spline.bHazeEditorOnlyDebugBool = true;
		if (Spline.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSpline(Spline, FLinearColor::Yellow);
#endif
	}

	FVector GetLocationAlongSpline(float Dist)
	{
		FVector SplineLoc = Spline.GetLocationAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World);
		SplineLoc += WaspMoveComp.SplineWorldOffset;
		if (!WaspMoveComp.SplineLocalOffset.IsZero())
		{
			FTransform SplineTransform = Spline.GetTransformAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World);
			SplineLoc += SplineTransform.TransformVector(WaspMoveComp.SplineLocalOffset);	
		}
		return SplineLoc;
	}

	void DisableCollision()
	{
		// This will stop wasp overlapping triggers, fix if necessary
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
		if (ToSpline.IsNearlyZero(CaptureRadius) && Owner.HasControl())
		{
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbCaptureSpline"), FHazeDelegateCrumbParams());
			return true;
		}

		return false;
	}

	UFUNCTION()
	void CrumbCaptureSpline(const FHazeDelegateCrumbData& CrumbData)
	{
		bCaptured = true;
		DisableCollision();

		FRotator PrevRot = MoveComp.PreviousOwnerRotation.Rotator();
		FRotator RotationalVelocity = FRotator::ZeroRotator;
		if (Owner.ActorDeltaSeconds > 0.f)
		{
			RotationalVelocity.Yaw = (Owner.GetActorRotation().Yaw - PrevRot.Yaw) / Owner.ActorDeltaSeconds;
			RotationalVelocity.Pitch = (Owner.GetActorRotation().Pitch - PrevRot.Pitch) / Owner.ActorDeltaSeconds;
		}
		Rotation.SnapTo(Owner.GetActorRotation(), RotationalVelocity);

		CaptureOffset.SnapTo(Owner.ActorLocation - GetLocationAlongSpline(BehaviourComp.DistanceAlongMoveSpline), MoveComp.GetVelocity());
		SetMutuallyExclusive(n"Flying", true); 
	}
};
