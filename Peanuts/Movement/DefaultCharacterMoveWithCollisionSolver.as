import Peanuts.Movement.CollisionSolver;

const float MaxAllowedMovedUnitsPerSecond = 1800.f;
const float FullStopAngle = -0.995f;

const FStatID STAT_MoveWithSolving(n"MoveWithSolving");

class UDefaultCharacterMoveWithCollisionSolver : UCollisionSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_MoveWithSolving);
#endif

		if (!ensure(ActorState.CurrentFloor != nullptr))
			return FCollisionSolverOutput();

#if EDITOR
		DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
		DebugComp.LogStartMoveWith(ActorState, MoveQuery);
#endif

		FCollisionSolverState SolverState;
		SolverState.StartLocation = MoveQuery.Location;
		SolverState.CurrentLocation = MoveQuery.Location;
		SolverState.RemainingDelta = MoveQuery.Delta;
		SolverState.RemainingTime = MoveQuery.DeltaTime;

		float RemainingRedirectUnits = MaxAllowedMovedUnitsPerSecond * MoveQuery.DeltaTime;

		FHazeHitResult LastBlockingHit;
		FShapeTracerIgnoresRestorePoint FloorIgnorePoint(ShapeTracer);
		{
			if (ActorState.CurrentFloor.Owner != nullptr)
				ShapeTracer.IgnoreActor(ActorState.CurrentFloor.Owner);
			else
				ShapeTracer.IgnorePrimitive(ActorState.CurrentFloor);

			FHazeHitResult Hit;
			int Iterations = 0;
			do
			{
				FVector SweepStartLocation = SolverState.CurrentLocation;
				FVector SweepDelta = SolverState.RemainingDelta;

				// Hack for fixing needing to move even when out of delta time - We only use delta time in this solver to figure out when we are done.
				// So it should be fine to monkey around with it.
				if (FMath::IsNearlyZero(SolverState.RemainingTime, KINDA_SMALL_NUMBER))
					SolverState.RemainingTime = FMath::Max(0.001f, SolverState.LastMovedTime);

				PrepareIterationStep(SolverState, SolverState.RemainingTime);

				if (DeltaProcessor != nullptr)
					DeltaProcessor.PreIteration(ActorState, SolverState, SolverState.RemainingTime);

				if (SweepAndMove(SolverState, SolverState.RemainingTime, Hit, true))
				{
					LastBlockingHit = Hit;
					if (RemainingRedirectUnits <= 0.f)
						break;

					if (Hit.bStartPenetrating)
					{
						FDepenetrationOutput Result;
						bool bHandled = false;
						if (DeltaProcessor != nullptr)
							bHandled = DeltaProcessor.HandleDepenetration(ActorState, SolverState, ShapeTracer, Hit, Result);

						if (!bHandled)
							Result = DepenetrationSolver.HandleStartPenetrating(ActorState, ShapeTracer, SolverState.CurrentLocation, false, Hit);

						SolverState.CurrentLocation += Result.DepenetrationDelta;
						continue;
					}

					float DeltaWallNormalDot = MoveQuery.Delta.GetSafeNormal().DotProduct(Hit.Normal);
					if (DeltaWallNormalDot < FullStopAngle)
						break;

					if (DeltaProcessor != nullptr)
						DeltaProcessor.ImpactCorrection(ActorState, SolverState, Hit);

					if (!SolverState.RemainingDelta.IsNearlyZero())
					{
						FVector ConstrainedNormal = Hit.Normal.ConstrainToPlane(ActorState.WorldUp).GetSafeNormal();
						FVector RedirectDirection = SolverState.RemainingDelta.ConstrainToPlane(ConstrainedNormal).GetSafeNormal();
						float RedirectAngle = Math::DotToRadians(SolverState.RemainingDelta.GetSafeNormal().DotProduct(RedirectDirection));

						float RedirectLength = SolverState.RemainingDelta.Size() / FMath::Cos(RedirectAngle);
						FVector RedirectVector = RedirectDirection * RedirectLength;

						float RedirectionAmount = RedirectVector.ConstrainToPlane(SolverState.RemainingDelta.GetSafeNormal()).Size();
						if (RedirectionAmount > RemainingRedirectUnits)
						{
							RedirectVector = RedirectDirection * (RemainingRedirectUnits / FMath::Sin(RedirectAngle));
							RedirectionAmount = RemainingRedirectUnits;
						}

						SolverState.RemainingDelta = RedirectVector;

						RemainingRedirectUnits -= RedirectionAmount;

#if EDITOR
						DebugComp.LogMoveWithRedirect(SweepStartLocation, SolverState, SweepDelta, MoveQuery.Delta, RemainingRedirectUnits / MaxAllowedMovedUnitsPerSecond * MoveQuery.DeltaTime, Hit.FHitResult);
#endif
					}
				}

				if (DeltaProcessor != nullptr)
					DeltaProcessor.PostIteration(ActorState, SolverState);

			} while(++Iterations < 10 && !SolverState.IsDone() && !SolverState.RemainingDelta.IsNearlyZero());
		}

		/*
		* Since we don't rotate the collisionshape with the primitive we are following the platform might have started clipping us.
		* Overlap check and depenetrate out of it.
		*/
		ShapeTracer.RestoreIgnores(FloorIgnorePoint);

		FMovementQueryParams OverlapParam;
		OverlapParam.From = SolverState.CurrentLocation;

		TArray<FOverlapResult> Overlaps;
		if (ShapeTracer.Overlap(OverlapParam, Overlaps))
		{
			bool bHandled = false;

			if (ActorState.bStandingOnFloor)
				bHandled = FloorStepDown(SolverState, Overlaps);

			if (!bHandled)
				SolverState.CurrentLocation = DepenetrationSolver.CalculateNonPushingDepenetration(ActorState, SolverState.CurrentLocation, false, ShapeTracer, Overlaps);
		}


		FCollisionSolverOutput Output;
		Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
		Output.PhysicsState.Impacts.ForwardImpact = LastBlockingHit.FHitResult;

#if EDITOR
		DebugComp.LogEndMoveWith(ActorState, MoveQuery, Output.PhysicalMove.MovedDelta);
#endif

		return Output;
	}

	bool FloorStepDown(FCollisionSolverState& SolverState, TArray<FOverlapResult>& Overlaps) const
	{
		// Try a sweep down.
		FVector TraceDelta = ActorState.WorldUp * 100.f;
		FHazeHitResult TopHit;
		if (ShapeTracer.CollisionSweep(SolverState.CurrentLocation + TraceDelta, SolverState.CurrentLocation, TopHit))
		{
			if (TopHit.bStartPenetrating)
				return false;

			if (TopHit.Component != ActorState.CurrentFloor)
				return false;

			if (Math::DotToDegrees(TopHit.Normal.DotProduct(ActorState.WorldUp)) > 60.f)
				return false;

			// Probably need a better fix here if were are not start penetrating.
			FVector DebugStartLocation = SolverState.CurrentLocation;
			SolverState.CurrentLocation = (SolverState.CurrentLocation + TraceDelta) - TraceDelta * TopHit.Time;

#if EDITOR
			DebugComp.LogMoveWithStepDown(SolverState, DebugStartLocation, DebugStartLocation - TraceDelta, TopHit.FHitResult);
#endif
			return true;
		}

		return false;
	}

};
