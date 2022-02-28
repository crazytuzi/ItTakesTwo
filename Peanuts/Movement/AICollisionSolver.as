import Peanuts.Movement.CollisionSolver;

class UAICollisionSolver : UCollisionSolver
{
	const int MaxIterations = 2;

	bool IsHitSurfaceWalkable(FHazeHitResult Hit) const
	{
		return IsHitSurfaceWalkableDefault(Hit.FHitResult, ActorState.WalkableSlopeAngle, ActorState.WorldUp);
	}

	bool LineTraceStepDown(FVector From, FHazeHitResult& OutResult, float BonusAmount = 0) const
	{
		const float CapsuleHalfHeight = ShapeTracer.GetCollisionShape().GetCapsuleHalfHeight() - 1;
		FMovementQueryLineParams LineTraceParams;
		LineTraceParams.From = From;
		LineTraceParams.From += (ActorState.WorldUp * CapsuleHalfHeight);
		LineTraceParams.To = From;
		LineTraceParams.To -= (ActorState.WorldUp * FMath::Max(ActorState.StepDownAmount + BonusAmount, 2.5f));

		// Line trace for more exact ground result
		ShapeTracer.LineTest(LineTraceParams, OutResult);
		return IsHitSurfaceWalkable(OutResult);
	}

	bool ShapeTraceStepDown(FVector From, FHazeHitResult& OutResult, float BonusAmount = 0) const
	{
		const float CapsuleHalfHeight = ShapeTracer.GetCollisionShape().GetCapsuleHalfHeight() - 1;
		FMovementQueryParams ShapeTraceParams;
		ShapeTraceParams.From = From;
		ShapeTraceParams.From += (ActorState.WorldUp * CapsuleHalfHeight);
		ShapeTraceParams.To = From;
		ShapeTraceParams.To -= (ActorState.WorldUp * FMath::Max(ActorState.StepDownAmount + BonusAmount, 2.5f));

		// Line trace for more exact ground result
		ShapeTracer.CollisionSweep(ShapeTraceParams, OutResult);
		return IsHitSurfaceWalkable(OutResult);
	}

	bool HandleSweepWasStartPenetrating(FVector& CurrentLocation, FHazeHitResult Overlap) const
	{
		FDepenetrationOutput DepenResult = DepenetrationSolver.HandleStartPenetrating(ActorState, ShapeTracer, CurrentLocation, false, Overlap);
		CurrentLocation += DepenResult.DepenetrationDelta;
		return DepenResult.bValidResult;
	}
}