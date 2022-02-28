
import Peanuts.Movement.DefaultCharacterCollisionSolver;

// Flying ai which needs to slide along ground/walls/ceiling but will never become grounded.
class UWaspFlyingCollisionSolver : UCollisionSolver
{
	int GetMaxNumberOfIterations() const
	{
		return 2;
	}

	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		if (ImpactType == EImpactSurfaceType::Wall)
		{
			if (PerformWaspStepUp(SolverState, Impact))
				return;
		}
		Super::ProcessImpact(SolverState, ImpactType, Impact);
	}

	// Simple step up so we won't get stuck on small ledges
	bool PerformWaspStepUp(FCollisionSolverState& SolverState, FHazeHitResult WallImpact) const
	{
		if (ActorState.StepUpAmount <= 0.f)
			return false;

		// We should only trigger a step up we are moving towards the surface horizontally.
		FVector LastHorizontalDelta = SolverState.LastMovedDelta.ConstrainToPlane(ActorState.WorldUp);
		float DirectionOfHit = WallImpact.Normal.DotProduct(LastHorizontalDelta);
		if (DirectionOfHit >= 0.f)
			return false;

		// No need to step up if wall is inclined upwards (as we'll have walkable slope angle to handle that)
		if (ActorState.WorldUp.DotProduct(WallImpact.Normal) > 0.f)
			return false;

		// We'll want to slide over stuff, so only step up slowly
		FCollisionSolverState OldState = SolverState;
		const FVector StepUpVector = ActorState.WorldUp * ActorState.StepUpAmount * SolverState.RemainingTime;

		// Sweep upwards
		FHazeHitResult UpHit;
		ShapeTracer.CollisionSweep(SolverState.CurrentLocation, SolverState.CurrentLocation + StepUpVector, UpHit);
		const FVector ActualStepUpVector = StepUpVector * UpHit.Time;
		SolverState.CurrentLocation += ActualStepUpVector;
		
		// Then sweep forwards
		FHazeHitResult ForwardHit;
		if (SweepAndMove(SolverState, SolverState.RemainingTime, ForwardHit, false))
		{
			EImpactSurfaceType SurfaceType = GetSurfaceTypeFromHit(ForwardHit);
			SolverState.SetHit(SurfaceType, ForwardHit);
		}

		// Don't sweep down, we're flying!
		return true;
	}
};
