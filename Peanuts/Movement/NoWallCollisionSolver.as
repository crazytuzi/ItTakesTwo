import Peanuts.Movement.DefaultCharacterCollisionSolver;

class UNoWallCollisionSolver : UDefaultCharacterCollisionSolver
{
	void HandleSweepWasStartPenetrating(FCollisionSolverState& SolverState, bool bFirstIteration, FHazeHitResult Hit) const override
	{
		if (ActorState.StepUpAmount > 0.f)
		{
			const FVector StepUpVector = ActorState.WorldUp * ActorState.StepUpAmount;

			FHazeHitResult StepUpHit;
			ShapeTracer.CollisionSweep(SolverState.CurrentLocation + StepUpVector, SolverState.CurrentLocation, StepUpHit);
			
			if (!StepUpHit.bStartPenetrating && StepUpHit.bBlockingHit)
			{
				SolverState.CurrentLocation += StepUpVector * (1.f - StepUpHit.Time);
				SolverState.PhysicsState.Impacts.DownImpact = StepUpHit.FHitResult;
				return;
			}
		}

		SolverState.IgnorePrimtiveNextIteration(Hit.Component);
	}

	EImpactSurfaceType PreProcessImpact(FCollisionSolverState& SolverState, FHazeHitResult& SweepHit) const override
	{
		// When hitting BSP our ImpactNormal could be very wonky.
		if (SweepHit.Actor == nullptr)
		{
			if (SweepHit.Normal.DotProduct(SweepHit.ImpactNormal) <= 0.5f)
			{
				FHitResult ConvertedResult = SweepHit.FHitResult;
				ConvertedResult.ImpactNormal = ConvertedResult.Normal;
				SweepHit.OverrideFHitResult(ConvertedResult);
			}		
		}

		return Super::PreProcessImpact(SolverState, SweepHit);
	}

	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const override
	{
		//			- Constrain the Hit/normal
		SolverState.SetHit(ImpactType, Impact);

		if (ImpactType == EImpactSurfaceType::Ground)
		{
			FCollisionRedirectInput Redirect;
			if (SolverState.PreviousPhysicsState.GroundedState == EHazeGroundedState::Grounded)
				Redirect.Method = EDeltaRedirectMethod::PreviousPlaneSlopeProject_PreserveLength;
			else
				Redirect.Method = EDeltaRedirectMethod::PlaneProject;
			
			Redirect.RedirectNormal = Impact.Normal;
			Redirect.Impact = Impact;

			RedirectImpact(SolverState, ImpactType, Redirect);
		}
		else
		{
			if (ImpactType == EImpactSurfaceType::Wall)
			{
				if (PerformStepUp(SolverState, Impact))
					return;
			}

			SolverState.MarkIterationAsIncomplete();
			SolverState.IgnorePrimtiveNextIteration(Impact.Component);
		}
	}
};
