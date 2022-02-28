import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingSettings;

class UIceSkatingCollisionSolver : UDefaultCharacterCollisionSolver
{
	FIceSkatingSolverSettings SolverSettings;

	bool IsHitSurfaceWalkable(FCollisionSolverState SolverState, FHazeHitResult Hit) const
	{
		float EscapeSpeed = Hit.FHitResult.Normal.DotProduct(SolverState.CurrentVelocity);
		if (EscapeSpeed > SolverSettings.SurfaceMaxEscapeSpeed)
			return false;

		return Super::IsHitSurfaceWalkable(SolverState, Hit);
	}

	void PerformStepDown(FCollisionSolverState& SolverState, float StepDownAmount) const override
	{
#if TEST
		FScopeCycleCounter Counter(STAT_StepDown);
#endif

		ensure(ActorState.StepDownAmount > 0.f);

		const FVector StartLocation = SolverState.CurrentLocation;

		const FVector TraceVector = -ActorState.WorldUp * FMath::Max(2.f, ActorState.StepDownAmount);

		FMovementQueryParams ShapeTraceParams;
		ShapeTraceParams.From = SolverState.CurrentLocation;
		ShapeTraceParams.To = SolverState.CurrentLocation + TraceVector;

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		FHazeHitResult ShapeHit;
		FHazeHitResult ExtraGroundTraceHit;

		bool bIsGrounded = false;

		if (ShapeTracer.CollisionSweep(ShapeTraceParams, ShapeHit))
		{
			// We want to do additional linetraces to see what surface is directly below the capsule,
			//	since, from the step downs' perspective, thats the target surface we're actually stepping down onto
			// We want to use that surface instead to do redirects and such, so you dont get "sucked down" when hitting
			//	the edge of platforms and so on.

			FVector HitToCurrLocHorizontal = SolverState.CurrentLocation - ShapeHit.ImpactPoint;
			HitToCurrLocHorizontal = HitToCurrLocHorizontal.ConstrainToPlane(ActorState.WorldUp);

			bool ShapeHitWalkable = IsHitSurfaceWalkable(SolverState, ShapeHit);
			if (ShapeHitWalkable)
			{
				// If the hit was walkable, triangulate downwards where the slope _should_ be below the capsule,
				//	and line-trace there.
				// If we dont do this, grounded state will break when standing on very steep surfaces with a low step-down height.
				
				if (HitToCurrLocHorizontal.Size() <= ShapeTracer.CollisionShape.Extent.X * 0.3f)
				{
					SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
				else
				{
					float DistanceToGround = CalculateDistanceToGroundFromSlopeHit(ShapeHit);
					if (IsEdgeHitGrounded(SolverState, HitToCurrLocHorizontal, FMath::Max(DistanceToGround, ActorState.StepDownAmount), ShapeHit, ExtraGroundTraceHit))
						SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
			}
			else
			{
				// Otherwise, we might be on the edge of a platform, so just line-trace downwards with the step-down amount
				//	to see if we're currently stepping down onto a surface below us.
				if (HitToCurrLocHorizontal.Size() > ShapeTracer.CollisionShape.Extent.X * 0.1f)
				{
					if (IsEdgeHitGrounded(SolverState, HitToCurrLocHorizontal, ActorState.StepDownAmount, ShapeHit, ExtraGroundTraceHit))
						SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
			}

			// ICESKATING: ONLY move if we're grounded, we dont want to step down onto unwalkables
			if (SolverState.PhysicsState.GroundedState == EHazeGroundedState::Grounded)
			{
				SolverState.CurrentLocation = ShapeHit.ActorLocation + GetPullbackAmount(ShapeHit, EImpactSurfaceType::Ground);
				
				if (ExtraGroundTraceHit.bBlockingHit)
					SolverState.SetHit(EImpactSurfaceType::Ground, ExtraGroundTraceHit);
				else
					SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
			}
		}
		else
		{
			SolverState.SetHit(EImpactSurfaceType::Ground, ShapeHit);
		}

#if EDITOR
		DebugComp.LogStepDown(StartLocation, SolverState.CurrentLocation, TraceVector, bIsGrounded, ExtraGroundTraceHit.FHitResult, ShapeHit.FHitResult);
#endif
	}
};
