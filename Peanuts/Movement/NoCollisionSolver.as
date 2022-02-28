import Peanuts.Movement.CollisionSolver;

class UNoCollisionSolver : UCollisionSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
		FCollisionSolverOutput Output;
		Output.PhysicalMove.MovedDelta = MoveQuery.Delta;
		Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;

		return Output;
	}
};
