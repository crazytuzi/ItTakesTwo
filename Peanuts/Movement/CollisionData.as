//import Peanuts.Movement.DefaultDepenetrationSolver;

// The solver state keeps track of the simulated object as we're tracing and redirecting.
// It is updated by each step in the collision solver.
struct FCollisionSolverState
{
	FVector StartLocation = FVector::ZeroVector;
	FVector CurrentLocation = FVector::ZeroVector;

	FVector RemainingDelta = FVector::ZeroVector;
	float RemainingTime = 0.f;

	FVector LastMovedDelta = FVector::ZeroVector;
	float LastMovedTime = 0.f;

	FVector CurrentVelocity = FVector::ZeroVector;
	bool bVelocityIsDirty = false;

	FVector PushedDelta = FVector::ZeroVector;

	FMovementPhysicsState PhysicsState;
	FMovementPhysicsState PreviousPhysicsState;
	EImpactSurfaceType LastImpactType;

	FShapeTracerIgnoresRestorePoint CurrentShapeTracerRestorePoint;
	bool bLastTraceIncomplete = false;

	TArray<AActor> FleetingActorIgnores;
	TArray<UPrimitiveComponent> FleetingPrimitivesIgnores;

	FPlatformPushData PushData;

	bool bLeavingGround = false;

	void Initialize(FCollisionMoveQuery MoveQuery, FCollisionSolverActorState ActorState)
	{
		StartLocation = MoveQuery.Location;
		CurrentLocation = MoveQuery.Location;
		RemainingDelta = MoveQuery.Delta;
		RemainingTime = MoveQuery.DeltaTime;
		CurrentVelocity = MoveQuery.Velocity;
		PhysicsState.GroundedState = ActorState.PhysicsState.GroundedState;
	}

	void IgnoreActorNextIteration(AActor ActorToIgnore)
	{
		FleetingActorIgnores.AddUnique(ActorToIgnore);
	}

	void IgnorePrimtiveNextIteration(UPrimitiveComponent ComponentToIgnore)
	{
		FleetingPrimitivesIgnores.AddUnique(ComponentToIgnore);
	}

	void MarkIterationAsIncomplete()
	{
		bLastTraceIncomplete = true;
	}

	void IgnoreActor(AActor ActorToIgnore)
	{
		if (!ensure(CurrentShapeTracerRestorePoint.RestorePointIsValid()))
			return;

		CurrentShapeTracerRestorePoint.AddActorToIgnore(ActorToIgnore);
	}

	void IgnorePrimtive(UPrimitiveComponent ComponentToIgnore)
	{
		if (!ensure(CurrentShapeTracerRestorePoint.RestorePointIsValid()))
			return;

		CurrentShapeTracerRestorePoint.AddPrimitiveToIgnore(ComponentToIgnore);
	}

	// Called before each collision solver iteration
	void IterationReset(UHazeShapeTracer& Tracer)
	{
		if (!bLastTraceIncomplete)
		{
			PreviousPhysicsState = PhysicsState;

			if (CurrentShapeTracerRestorePoint.RestorePointIsValid())
			{
				Tracer.RestoreIgnores(CurrentShapeTracerRestorePoint);
				CurrentShapeTracerRestorePoint = FShapeTracerIgnoresRestorePoint();
			}
		}

		if (FleetingActorIgnores.Num() > 0 || FleetingPrimitivesIgnores.Num() > 0)
		{
			if (!bLastTraceIncomplete)
				CurrentShapeTracerRestorePoint = FShapeTracerIgnoresRestorePoint(Tracer);

			Tracer.IgnoreActors(FleetingActorIgnores);
			Tracer.IgnorePrimitives(FleetingPrimitivesIgnores);
			FleetingActorIgnores.Reset();
			FleetingPrimitivesIgnores.Reset();
		}

		bLastTraceIncomplete = false;
	}

	FVector PeekDelta(float Time) const
	{
		return RemainingDelta * (Time / RemainingTime);
	}

	void AdvanceDelta(float Time)
	{
		LastMovedTime = Time;
		LastMovedDelta = PeekDelta(Time);

		RemainingDelta -= LastMovedDelta;
		RemainingTime -= LastMovedTime;

		if (bVelocityIsDirty)
		{
			// Avoid precision jitteryness if we moved very little
			if (!FMath::IsNearlyZero(LastMovedTime, KINDA_SMALL_NUMBER))
				CurrentVelocity = LastMovedDelta / LastMovedTime;
		}
	}

	void AdvanceDeltaAndLocation(float Time)
	{
		LastMovedTime = Time;
		LastMovedDelta = PeekDelta(Time);
		CurrentLocation += LastMovedDelta;

		RemainingDelta -= LastMovedDelta;
		RemainingTime -= LastMovedTime;

		if (bVelocityIsDirty)
		{
			// Avoid precision jitteryness if we moved very little
			if (!FMath::IsNearlyZero(LastMovedTime, KINDA_SMALL_NUMBER))
				CurrentVelocity = LastMovedDelta / LastMovedTime;
		}
	}

	void AdvanceDeltaAndLocation(float Time, FVector CustomDeltaMove)
    {
        const FVector LastLocation = CurrentLocation;
        AdvanceDelta(Time);
        CurrentLocation = LastLocation + CustomDeltaMove;
    }

	void SetHit(EImpactSurfaceType ImpactType, FHazeHitResult Impact)
	{
		LastImpactType = ImpactType;
		switch (ImpactType)
		{
			case EImpactSurfaceType::Ceiling:
				PhysicsState.Impacts.UpImpact = Impact.FHitResult;
				break;
			case EImpactSurfaceType::Wall:
			case EImpactSurfaceType::InvisibleWall:
				PhysicsState.Impacts.ForwardImpact = Impact.FHitResult;
				break;
			case EImpactSurfaceType::Ground:
				PhysicsState.Impacts.DownImpact = Impact.FHitResult;
				break;
			default:
				ensure(false); // waht;
			break;
		}
	}

	FVector GetMovedDelta() const property
	{
		return CurrentLocation - StartLocation;
	}	

	bool IsDone() const
	{
		if (bLastTraceIncomplete)
			return false;

		return FMath::IsNearlyZero(RemainingTime, KINDA_SMALL_NUMBER);
	}

	bool IsGrounded() const
	{
		return PhysicsState.GroundedState == EHazeGroundedState::Grounded && PhysicsState.Impacts.DownImpact.bBlockingHit;
	}
}

enum EImpactSurfaceType
{
	Wall,
	InvisibleWall,
	Ceiling,
	Ground
}

enum EDeltaRedirectMethod
{
	PlaneProject,
	PlaneProject_PreserveLength,
	PreviousPlaneSlopeProject_PreserveLength,
	PlaneProject_PreserveVerticalLength,
}

struct FCollisionRedirectInput
{
	EDeltaRedirectMethod Method;
	FHazeHitResult Impact;
	FVector RedirectNormal = FVector::ZeroVector;	
}

struct FDepenetrationOutput
{
	bool bValidResult = false;

	bool bIsSquished = false;
	FVector DepenetrationDelta = FVector::ZeroVector;
	FPlatformPushData PushData;

	// If set we will ignore this actor for the next frame.
	AActor IgnoreActor = nullptr;
};
