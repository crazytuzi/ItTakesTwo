
import Peanuts.Movement.AICollisionSolver;

// This solver should be used for AIs who is flying and is never going to touch the ground
class UAICharacterAirborneDetectionSolver : UAICollisionSolver
{
	const int MaxIteractionTypes = 4;
	int SweepIteration = FMath::RandRange(-1, MaxIteractionTypes);
	FVector CenterOffset;

	UFUNCTION(BlueprintOverride)
	void UpdateDeltaProcessor(UHazeDeltaProcessorBase InDeltaProcessor) override
	{
		Super::UpdateDeltaProcessor(InDeltaProcessor);
		if(HasAnyImpacts())
		{
			// If we have impacts, we need to sweep expensive until we dont have them.
			SweepIteration = 0;
		}
		else
		{
			SweepIteration++;
			if(SweepIteration > MaxIteractionTypes)
			{
				SweepIteration = 0;
			}
		}

		CenterOffset = ActorState.OwningActor.GetActorLocation() - ActorState.OwningActor.GetActorCenterLocation();
	}

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const override
	{
#if EDITOR
		DebugComp.FrameReset(ActorState, MoveQuery, ShapeTracer.ColliderOffset, this);
		DebugComp.LogStartState(ActorState, MoveQuery);
#endif

		FCollisionSolverState SolverState;
		SolverState.Initialize(MoveQuery, ActorState);

		// We only validate the movement on the controlside
		if(ActorState.OwningActor.HasControl())
		{
			CollisionCheckDeltaInternal(MoveQuery, SolverState);
		}
		// The remote side will always be where the controlside tells it to be
		else
		{	
			SolverState.AdvanceDeltaAndLocation(SolverState.RemainingTime);
			SolverState.PhysicsState = ActorState.PhysicsState;
		}
		
		FCollisionSolverOutput Output;
		Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
		Output.PhysicalMove.RequestedVelocity = SolverState.CurrentVelocity;
		Output.PhysicsState = SolverState.PhysicsState;

		return Output;
	}

	void CollisionCheckDeltaInternal(const FCollisionMoveQuery& MoveQuery, FCollisionSolverState& SolverState) const
	{
		// The airmove should only do 1 iteration
		SweepAndMoveDelta(SolverState, 0);
	}

	void SweepAndMoveDelta(FCollisionSolverState& SolverState, int CurrentIteration) const
	{
		// We are stuck somehow
		if(CurrentIteration >= MaxIterations)
		{
			PrintError("Invalid movement: " + ActorState.OwningActor + " is stuck", Duration = 0.f);
			return;
		}

		if(SolverState.RemainingDelta.IsNearlyZero())
			return;

		SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		const FVector CurrentDeltaMove = SolverState.RemainingDelta;
		const FVector MoveDirection = CurrentDeltaMove.GetSafeNormal();

		FHazeHitResult DeltaMoveImpact;
		bool bFoundCollision = false;
		if(SweepIteration == 0)
		{
			// We only do a expensive trace from time to time to validate that we are not inside anything
			FMovementQueryParams DeltaMoveShapeTraceParams;
			DeltaMoveShapeTraceParams.From = SolverState.CurrentLocation;
			DeltaMoveShapeTraceParams.To = DeltaMoveShapeTraceParams.From + CurrentDeltaMove;
			bFoundCollision = ShapeTracer.CollisionSweep(DeltaMoveShapeTraceParams, DeltaMoveImpact);
		}
		else if(SweepIteration == 1)
		{
			// Most of the time, we will just do a line trace since we assume that we are in free air
			FMovementQueryLineParams DeltaMoveLineTraceParams;

			// Since the actors location might not be in the middle, we offset the trace
			DeltaMoveLineTraceParams.From = SolverState.CurrentLocation - CenterOffset;

			// We also move the trace start position to be at the edge of capsule when we linetrace
			const FCollisionShape& Shape = ShapeTracer.GetCollisionShape();
			const FVector MoveDir = SolverState.RemainingDelta.GetSafeNormal();
			
			const float HorizontalAlpha = 1.f - FMath::Abs(MoveDir.DotProduct(ActorState.WorldUp));
			DeltaMoveLineTraceParams.From += (MoveDir - MoveDir.ConstrainToDirection(ActorState.WorldUp)) * (HorizontalAlpha * Shape.GetCapsuleRadius());

			const float VerticalAlpha = FMath::Abs(MoveDir.DotProduct(ActorState.WorldUp));
			DeltaMoveLineTraceParams.From += ActorState.WorldUp * (VerticalAlpha * Shape.GetCapsuleHalfHeight());

			DeltaMoveLineTraceParams.To = DeltaMoveLineTraceParams.From + CurrentDeltaMove;
			bFoundCollision = ShapeTracer.LineTest(DeltaMoveLineTraceParams, DeltaMoveImpact);
		}

		if(bFoundCollision)
		{
			if(DeltaMoveImpact.bStartPenetrating)
			{
				// We are stuck inside something and need to get out
				HandleSweepWasStartPenetrating(SolverState.CurrentLocation, DeltaMoveImpact);
				SweepAndMoveDelta(SolverState, CurrentIteration + 1);
				return;
			}
			else
			{
				UpdateLocationFromHit(SolverState, DeltaMoveImpact);
				SolverState.AdvanceDelta(SolverState.RemainingTime * DeltaMoveImpact.Time);
	
				if(MoveDirection.DotProduct(ActorState.WorldUp) > KINDA_SMALL_NUMBER)
				{
					// We are moving up
					SolverState.SetHit(EImpactSurfaceType::Ceiling, DeltaMoveImpact);
				}
				else if(MoveDirection.ConstrainToPlane(ActorState.WorldUp).Size() > KINDA_SMALL_NUMBER)
				{
					// We are moving horizontally
					SolverState.SetHit(EImpactSurfaceType::Wall, DeltaMoveImpact);		
				}
				else
				{
					// We are moving down or not moving at all
					SolverState.SetHit(EImpactSurfaceType::Ground, DeltaMoveImpact);
					SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				}
			}
		}
		else
		{
			// We have not hit anything and can move the entire distance
			SolverState.AdvanceDeltaAndLocation(SolverState.RemainingTime);
		}
	}
};
