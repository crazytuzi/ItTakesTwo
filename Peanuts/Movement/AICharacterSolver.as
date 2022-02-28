import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Movement.DefaultCharacterRemoteCollisionSolver;

const FStatID STAT_AIStepDown(n"AIStepDown");

class UAICharacterSolver : UDefaultCharacterCollisionSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const override
	{
		if (MoveQuery.Delta.IsNearlyZero())
		{
			if (CanAvoidCalculatingMovement())
			{
#if EDITOR
				DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
				DebugComp.LogStartState(ActorState, MoveQuery);
#endif

				FCollisionSolverOutput Output;
				Output.PhysicsState.GroundedState = ActorState.PhysicsState.GroundedState;
				Output.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;
				
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;

#if EDITOR
				DebugComp.LogStandStill(MoveQuery, Output);
#endif

				return Output;
			}
		}

		return Super::CollisionCheckDelta(MoveQuery);
	}

	float CalculateIterationTime(const FCollisionSolverState& SolverState) const override
	{
		return SolverState.RemainingTime;
	}

	bool SweepAndMove(FCollisionSolverState& SolverState, float IterationTime, FHazeHitResult& OutHit, bool bDebugLog = true) const override
	{
		if (SolverState.RemainingDelta.IsNearlyZero())
		{
			FHitResult ModifiedResult = OutHit.FHitResult;
			ModifiedResult.Time = 1.f;
			OutHit.OverrideFHitResult(ModifiedResult);
			SolverState.AdvanceDeltaAndLocation(IterationTime);
			return false;
		}

		return Super::SweepAndMove(SolverState, IterationTime, OutHit, bDebugLog);
	}

	void PerformStepDown(FCollisionSolverState& SolverState, float StepDownAmount) const override
	{
#if TEST
		FScopeCycleCounter Counter(STAT_AIStepDown);
#endif

		ensure(StepDownAmount > 0.f);

		const FVector StartLocation = SolverState.CurrentLocation;

		const FVector TraceVector = -ActorState.WorldUp * ActorState.StepDownAmount;

		FMovementQueryParams ShapeTraceParams;
		ShapeTraceParams.From = SolverState.CurrentLocation;
		ShapeTraceParams.To = SolverState.CurrentLocation + TraceVector;

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		FHazeHitResult ShapeHit;
		FHazeHitResult ExtraGroundTraceHit;

		bool bIsGrounded = false;

		if (ShapeTracer.CollisionSweep(ShapeTraceParams, ShapeHit))
		{
			if (IsHitSurfaceWalkable(SolverState, ShapeHit))
				EHazeGroundedState::Grounded;

			SolverState.CurrentLocation += TraceVector * ShapeHit.Time;
			SolverState.SetHit(EImpactSurfaceType::Ground, ExtraGroundTraceHit);
		}
		else
		{
			SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
		}

#if EDITOR
		DebugComp.LogStepDown(StartLocation, SolverState.CurrentLocation, TraceVector, bIsGrounded, ExtraGroundTraceHit.FHitResult, ShapeHit.FHitResult);
#endif
	}

	bool CanAvoidCalculatingMovement() const
	{
		UPrimitiveComponent CurrentFloor = ActorState.CurrentFloor;

		if (CurrentFloor == nullptr)
		{
			if (!ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
				return false;
			CurrentFloor = ActorState.PhysicsState.Impacts.DownImpact.Component;
		}

		if (CurrentFloor != nullptr && CurrentFloor.Mobility == EComponentMobility::Static)
			return true;

		return false;
	}
};

class UAICharacterRemoteCollisionSolver : UDefaultCharacterRemoteCollisionSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const override
	{
		if (MoveQuery.Delta.IsNearlyZero())
		{
			if (CanAvoidCalculatingMovement())
			{
#if EDITOR
				DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
				DebugComp.LogStartState(ActorState, MoveQuery);
#endif

				FCollisionSolverOutput Output;
				Output.PhysicsState.GroundedState = ActorState.PhysicsState.GroundedState;
				Output.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;
				
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;

#if EDITOR
				DebugComp.LogStandStill(MoveQuery, Output);
#endif

				return Output;
			}
		}

		return Super::CollisionCheckDelta(MoveQuery);
	}

	bool CanAvoidCalculatingMovement() const
	{
		UPrimitiveComponent CurrentFloor = ActorState.CurrentFloor;

		if (CurrentFloor == nullptr)
		{
			if (!ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
				return false;
			CurrentFloor = ActorState.PhysicsState.Impacts.DownImpact.Component;
		}

		if (CurrentFloor != nullptr && CurrentFloor.Mobility == EComponentMobility::Static)
			return true;

		return false;
	}
};
