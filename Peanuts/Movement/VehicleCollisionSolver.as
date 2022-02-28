import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Movement.DefaultCharacterRemoteCollisionSolver;

class UVehicleCollisionSolver : UDefaultCharacterCollisionSolver
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

class UVehicleRemoteCollisionSolver : UDefaultCharacterRemoteCollisionSolver
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