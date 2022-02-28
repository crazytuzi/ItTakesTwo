import Peanuts.Movement.DefaultDepenetrationSolver;
import Peanuts.Movement.GroundTraceFunctions;
import Peanuts.Movement.MovementDebugDataComponent;
import Peanuts.Movement.CollisionData;
import Peanuts.Movement.DeltaProcessor;

const float DefaultMaxTimeStep = 1.f / 30.f;
const int MaxIterationCount = 4;

const FStatID STAT_UpdateGroundedState(n"UpdateGroundedState");
const FStatID STAT_HandleDepenetration(n"HandleDepenetration");

const FStatID STAT_CollisionSolving(n"CollisionSolver");

const FStatID STAT_IterationID0(n"IterationID0");
const FStatID STAT_IterationID1(n"IterationID1");
const FStatID STAT_IterationID2(n"IterationID2");
const FStatID STAT_IterationID3(n"IterationID3");
const FStatID STAT_IterationID4(n"IterationID4");
const FStatID STAT_IterationID5(n"IterationID5");
const FStatID STAT_IterationID6(n"IterationID6");
const FStatID STAT_IterationID7(n"IterationID7");
const FStatID STAT_IterationID8(n"IterationID8");
const FStatID STAT_IterationID9(n"IterationID9");
const FStatID STAT_ITERATIONERROR(n"ITERATIONERROR");

#if TEST
const FStatID& GetIterationID(int Iteration)
{
	switch(Iteration)
	{
		case 0:
			return STAT_IterationID0;
		case 1:
			return STAT_IterationID1;
		case 2:
			return STAT_IterationID2;
		case 3:
			return STAT_IterationID3;
		case 4:
			return STAT_IterationID4;
		case 5:
			return STAT_IterationID5;
		case 6:
			return STAT_IterationID6;
		case 7:
			return STAT_IterationID7;
		case 8:
			return STAT_IterationID8;
		case 9:
			return STAT_IterationID9;
	}

	return STAT_ITERATIONERROR;
}
#endif

class UCollisionSolver : UHazeCollisionSolver
{
	FDefaultDepenetrationSolver DepenetrationSolver;

#if EDITOR
	UMovementDebugDataComponent DebugComp = nullptr;
#endif

	UDeltaProcessor DeltaProcessor;

	UFUNCTION(BlueprintOverride)
	void OnCreated(AHazeActor OwningActor)
	{
#if EDITOR
		DebugComp = UMovementDebugDataComponent::GetOrCreate(OwningActor);
		DepenetrationSolver.DebugComp = DebugComp;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void UpdateDeltaProcessor(UHazeDeltaProcessorBase InDeltaProcessor)
	{
		DeltaProcessor = Cast<UDeltaProcessor>(InDeltaProcessor);
#if EDITOR
		if (DeltaProcessor != nullptr)
			DeltaProcessor.DebugComp = DebugComp;
#endif
	}

	int GetMaxNumberOfIterations() const
	{
		return MaxIterationCount;
	}

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
#if EDITOR
		DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
		DebugComp.LogStartState(ActorState, MoveQuery);
#endif

#if TEST
		FScopeCycleCounter EntryCounter(STAT_CollisionSolving);
#endif

		FCollisionSolverOutput Output;

		// Create and setup delta tracker
		FCollisionSolverState SolverState;
		SolverState.StartLocation = MoveQuery.Location;
		SolverState.CurrentLocation = MoveQuery.Location;
		SolverState.RemainingDelta = MoveQuery.Delta;
		SolverState.RemainingTime = MoveQuery.DeltaTime;
		SolverState.CurrentVelocity = MoveQuery.Velocity;
		if (ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
			SolverState.bLeavingGround = MoveQuery.Velocity.DotProduct(ActorState.PhysicsState.Impacts.DownImpact.Normal) > 10.f;

		SolverState.PhysicsState.GroundedState = ActorState.PhysicsState.GroundedState;
		SolverState.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;

		int Iterations = 0;
		do
		{
#if TEST
			FScopeCycleCounter Counter(GetIterationID(Iterations));
#endif

#if EDITOR
			DebugComp.LogIterationBegin(Iterations);
#endif

			float IterationTime = CalculateIterationTime(SolverState);

			PrepareIterationStep(SolverState, IterationTime);
			PerformIterationStep(SolverState, IterationTime, Iterations == 0);

			if (SolverState.PhysicsState.bIsSquished)
				break;

		} while(++Iterations < GetMaxNumberOfIterations() && !SolverState.IsDone());

		PostAllIterations(SolverState);

		Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
		Output.PhysicalMove.RequestedVelocity = SolverState.CurrentVelocity;
		Output.PhysicsState = SolverState.PhysicsState;
		Output.PhysicsState.PushData = SolverState.PushData;

#if EDITOR
		DebugComp.LogEndState(SolverState, Output, Iterations);
#endif

		return Output;
	}

	float CalculateIterationTime(const FCollisionSolverState& SolverState) const
	{
		const float IterationTraceDistance = ShapeTracer.CollisionShape.Extent.X * 0.85f;
		const float RemainingDistance = SolverState.RemainingDelta.Size();

		if (RemainingDistance > IterationTraceDistance)
		{
			float DistancePercentage = IterationTraceDistance / RemainingDistance;
			float IterationDistanceTime = SolverState.RemainingTime * DistancePercentage;

			const float MaxIterationTime = FMath::Max(DefaultMaxTimeStep, IterationDistanceTime);
			return FMath::Min(SolverState.RemainingTime, MaxIterationTime);
		}

		return SolverState.RemainingTime;
	}

	void PrepareIterationStep(FCollisionSolverState& SolverState, float IterationTime) const
	{
		SolverState.IterationReset(ShapeTracer);

		// We want to start each iteration as airborne until proven otherwise!
		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;

		if (DeltaProcessor != nullptr)
			DeltaProcessor.PreIteration(ActorState, SolverState, IterationTime);
	}

	void PerformIterationStep(FCollisionSolverState& SolverState, float IterationTime, bool bFirstIteration) const
	{
		FHazeHitResult SweepHit;

		if (SweepAndMove(SolverState, IterationTime, SweepHit))
		{	
			if (SweepHit.bStartPenetrating || SweepHit.Time == 0)
			{
				FHitResult ModifiedResult = SweepHit.FHitResult;
				ModifiedResult.bStartPenetrating = true;
				SweepHit.OverrideFHitResult(ModifiedResult);
				HandleSweepWasStartPenetrating(SolverState, bFirstIteration, SweepHit);
				return;
			}

			const EImpactSurfaceType ImpactType = PreProcessImpact(SolverState, SweepHit);
			ProcessImpact(SolverState, ImpactType, SweepHit);
		}
		
		// We always process the trace, but only handle it if we return that it is a impact
		PostSweep(SolverState);
	}

	EImpactSurfaceType PreProcessImpact(FCollisionSolverState& SolverState, FHazeHitResult& SweepHit) const
	{
		if (DeltaProcessor != nullptr)
			DeltaProcessor.ImpactCorrection(ActorState, SolverState, SweepHit);
			
		return GetSurfaceTypeFromHit(SweepHit);
	}

	void PostSweep(FCollisionSolverState& SolverState) const
	{
		if (SolverState.PhysicsState.GroundedState != EHazeGroundedState::Grounded)
			UpdateGroundedState(SolverState);

		if (DeltaProcessor != nullptr)
			DeltaProcessor.PostIteration(ActorState, SolverState);
	}

	void PostAllIterations(FCollisionSolverState& SolverState) const
	{}

	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		//			- Constrain the Hit/normal
		SolverState.SetHit(ImpactType, Impact);

		FCollisionRedirectInput Redirect;
		Redirect.Method = EDeltaRedirectMethod::PlaneProject;
		Redirect.RedirectNormal = Impact.Normal;
		Redirect.Impact = Impact;

		SolverState.bVelocityIsDirty = true;

		RedirectImpact(SolverState, ImpactType, Redirect);
	}

	void HandleSweepWasStartPenetrating(FCollisionSolverState& SolverState, bool bFirstIteration, FHazeHitResult Hit) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_HandleDepenetration);
#endif
		FDepenetrationOutput DepenResult;
		FVector derp;
		bool bHandled = false;

		if (DeltaProcessor != nullptr)
			bHandled = DeltaProcessor.HandleDepenetration(ActorState, SolverState, ShapeTracer, Hit, DepenResult);

		if (!bHandled)
			DepenResult = DepenetrationSolver.HandleStartPenetrating(ActorState, ShapeTracer, SolverState.CurrentLocation, bFirstIteration, Hit);

		SolverState.CurrentLocation += DepenResult.DepenetrationDelta;
		if (bFirstIteration)
			SolverState.PushData = DepenResult.PushData;
		
		SolverState.PhysicsState.bIsSquished = DepenResult.bIsSquished;
		SolverState.MarkIterationAsIncomplete();

		if (DeltaProcessor != nullptr)
			DeltaProcessor.OnDepentrated(ActorState, SolverState, DepenResult);

		if (DepenResult.IgnoreActor != nullptr)
			SolverState.IgnoreActorNextIteration(DepenResult.IgnoreActor);

#if EDITOR
		DebugComp.LogDepenetrate(Hit.FHitResult, DepenResult);
#endif
	}

	void RedirectImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FCollisionRedirectInput Input) const
	{
		FVector PrevDelta = SolverState.RemainingDelta;

		float OldDeltaLength = SolverState.RemainingDelta.Size();

		switch(Input.Method)
		{
			case EDeltaRedirectMethod::PlaneProject:
			{
				// Projects the delta directly onto the plane. The standard one.
				SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToPlane(Input.RedirectNormal);
			}
			break;

			case EDeltaRedirectMethod::PlaneProject_PreserveLength:
			{
				// Projects the delta directly onto the plane. The standard one.
				const float DeltaSize = SolverState.RemainingDelta.Size();
				SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToPlane(Input.RedirectNormal);
				SolverState.RemainingDelta = SolverState.RemainingDelta.GetSafeNormal() * DeltaSize;
			}
			break;

			case EDeltaRedirectMethod::PreviousPlaneSlopeProject_PreserveLength:
			{
				// Performs slope projection, which will preserve the world-up-relative angle of the delta
				// Also preserves the length of the delta
				float HorizontalSize = SolverState.RemainingDelta.ConstrainToPlane(SolverState.PreviousPhysicsState.Impacts.DownImpact.ImpactNormal).Size();

				FVector ConstrainedDelta = Math::ConstrainVectorToSlope(SolverState.RemainingDelta, Input.RedirectNormal, ActorState.WorldUp);
				SolverState.RemainingDelta = ConstrainedDelta.GetSafeNormal() * HorizontalSize;
			}
			break;

			case EDeltaRedirectMethod::PlaneProject_PreserveVerticalLength:
			{
				// Splits the delta into two parts, horizontal (perpendicualar to slope down) and vertical (aligned with slope down)
				// The horizontal part is plane-projected, while the vertical is completely preserved
				FVector PlaneRight = ActorState.WorldUp.CrossProduct(Input.RedirectNormal);
				PlaneRight.Normalize();

				FVector PlaneDown = PlaneRight.CrossProduct(Input.RedirectNormal);

				FVector HoriDelta, VertDelta;
				Math::DecomposeVector(VertDelta, HoriDelta, SolverState.RemainingDelta, PlaneDown);
				SolverState.RemainingDelta = HoriDelta.ConstrainToPlane(Input.RedirectNormal) + VertDelta;
			}
			break;

			default:
				// Not implemented?
				ensure(false);
			break;
		}

#if EDITOR
		DebugComp.LogRedirect(Input, PrevDelta, SolverState.RemainingDelta);
#endif
	}

	void UpdateGroundedState(FCollisionSolverState& SolverState) const
	{	
#if TEST
		FScopeCycleCounter Counter(STAT_UpdateGroundedState);
#endif

		FMovementQueryParams GroundedParams;
		GroundedParams.From = SolverState.CurrentLocation;
		GroundedParams.To = SolverState.CurrentLocation - ActorState.WorldUp * 2.f;

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		FHazeHitResult GroundHit;
		FHazeHitResult LineHit;

		bool bGroundCheckIsValid = false;

		// For grounded checks we sweep the shape a bit downwards to see if we are directly above ground.
		// It doesn't actually move the shape.
		if (ShapeTracer.CollisionSweep(GroundedParams, GroundHit))
		{
			if (IsHitSurfaceWalkable(SolverState, GroundHit))
				bGroundCheckIsValid = true;

			if (bGroundCheckIsValid)
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				SolverState.SetHit(EImpactSurfaceType::Ground, GroundHit);
			}
			else
			{
				SolverState.SetHit(EImpactSurfaceType::Ground, GroundHit);
			}
		}
		else
		{
			SolverState.SetHit(EImpactSurfaceType::Ground, GroundHit);
		}

#if EDITOR
		DebugComp.LogGroundedCheck(SolverState.CurrentLocation, GroundHit.FHitResult, LineHit.FHitResult, false, bGroundCheckIsValid);
#endif
	}

	bool IsHitSurfaceWalkable(FCollisionSolverState SolverState, FHazeHitResult Hit) const
	{
		return IsHitSurfaceWalkableDefault(Hit.FHitResult, ActorState.WalkableSlopeAngle, ActorState.WorldUp);
	}

	bool IsHitSurfaceCeiling(FHazeHitResult Hit) const
	{
		if (!Hit.bBlockingHit)
			return true;

		if (Hit.Component == nullptr)
			return true;

		float CosAngle = FMath::Cos(ActorState.CeilingAngle * DEG_TO_RAD);
		float NormalDot = Hit.Normal.DotProduct(-ActorState.WorldUp);

		return NormalDot > CosAngle;
	}

	EImpactSurfaceType GetSurfaceTypeFromHit(FHazeHitResult HitResult) const
	{
		// Use default IsHitSurfaceWalkable here to only check the walkable slope angle
		// Since the function 'IsHitSurfaceWalkable' might declare floor as not walkable for other reasons.
		// But even if its not walkable, we still wanna classify the ground as floor
		if (IsHitSurfaceWalkableDefault(HitResult.FHitResult, ActorState.WalkableSlopeAngle, ActorState.WorldUp))
		{
			return EImpactSurfaceType::Ground;
		}
		else if (IsHitSurfaceCeiling(HitResult))
		{
			return EImpactSurfaceType::Ceiling;
		}
		else
		{
			return EImpactSurfaceType::Wall;
		}			
	}

	bool SweepAndMove(FCollisionSolverState& TrackerToSweep, float IterationTime, FHazeHitResult& OutHit, bool bDebugLog = true) const
	{
		float TraceTime;
		FVector TraceDelta;

		// To keep consistant behaviour in different frame rates limit how far we trace during a single sweep,
		// and sweep multiple times instead in lower frame rates
		TraceTime = IterationTime;
		TraceDelta = TrackerToSweep.PeekDelta(TraceTime);

		FMovementQueryParams SweepParams;
		SweepParams.From = TrackerToSweep.CurrentLocation;
		SweepParams.To = SweepParams.From + TraceDelta;

		if (TraceDelta.IsNearlyZero())
		{
			// If we have a zero delta then collisionsweep will not return anything, We still need to make sure we are currently not overlapping anything.
			TArray<FOverlapResult> Overlaps;
			if (ShapeTracer.Overlap(SweepParams, Overlaps))
			{		
				FHitResult ModifiedResult = OutHit.FHitResult;	
				ModifiedResult.bStartPenetrating = true;
				ModifiedResult.BlockingHit = true;
				ModifiedResult.Component = Overlaps[0].Component;
				ModifiedResult.Actor = Overlaps[0].Actor;
				ModifiedResult.Time = 0.f;
				OutHit.OverrideFHitResult(ModifiedResult);
				TrackerToSweep.MarkIterationAsIncomplete();
				return true;
			}

			TrackerToSweep.AdvanceDelta(TraceTime);
			
			return false;
		}

		bool bHasCollision = ShapeTracer.CollisionSweep(SweepParams, OutHit);

		// If we are startpenetrating then we want to early out, resolve it and then run a new iteration.
		if (OutHit.bStartPenetrating)
		{
			TrackerToSweep.MarkIterationAsIncomplete();
			return true;
		}

		// Update the delta and velocity.
		UpdateLocationFromHit(TrackerToSweep, OutHit);
		TrackerToSweep.AdvanceDelta(TraceTime * OutHit.Time);

#if EDITOR
		if (bDebugLog)
			DebugComp.LogCollisionSweep(SweepParams.From, SweepParams.To, OutHit.FHitResult);
#endif

		return bHasCollision;
	}

	void UpdateLocationFromHit(FCollisionSolverState& State, FHazeHitResult Hit) const
	{
		if (!Hit.bBlockingHit)
		{
			State.CurrentLocation = Hit.TraceEnd - ShapeTracer.ColliderOffset;
			return;
		}

		State.CurrentLocation = Hit.ActorLocation;

		const EImpactSurfaceType SurfaceType = GetSurfaceTypeFromHit(Hit);
		State.CurrentLocation += GetPullbackAmount(Hit, SurfaceType);
	}

	FVector GetPullbackAmount(FHazeHitResult Hit, EImpactSurfaceType ImpactType) const
	{
		if (ImpactType == EImpactSurfaceType::Ground)
			return ActorState.WorldUp * 0.2f;
		else
			return Hit.Normal.ConstrainToPlane(ActorState.WorldUp).SafeNormal * 0.5f;
	}
};

