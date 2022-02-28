import Peanuts.Movement.CollisionSolver;

class UHazeboyTankSolver : UCollisionSolver
{
	void RedirectImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FCollisionRedirectInput Input) const override
	{
		FVector RedirectNormal = Input.Impact.Normal;
		RedirectNormal = RedirectNormal.ConstrainToPlane(FVector::UpVector);

		ensure(!RedirectNormal.IsNearlyZero());

		RedirectNormal.Normalize();
		SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToPlane(RedirectNormal);
		SolverState.RemainingDelta = SolverState.RemainingDelta.ConstrainToPlane(FVector::UpVector);
	}

	void HandleSweepWasStartPenetrating_Derp(FCollisionSolverState& SolverState, bool bFirstIteration, FHazeHitResult Hit) const
	{
		FVector FlatNormal = Hit.Normal.ConstrainToPlane(FVector::UpVector);
		FlatNormal.Normalize();

		SolverState.CurrentLocation += FlatNormal * Hit.PenetrationDepth;
	}
}