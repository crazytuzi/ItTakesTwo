import Peanuts.Movement.AICollisionSolver;

// This solver should be used for AIs who is not going to walk over edges.
// It is optimized for air and relativly flat surfaces
class UAICharacterGroundedDetectionSolver : UAICollisionSolver
{
	const int MaxIteractionTypes = 4;
	int SweepIteration = FMath::RandRange(-1, MaxIteractionTypes);

	UFUNCTION(BlueprintOverride)
	void UpdateDeltaProcessor(UHazeDeltaProcessorBase InDeltaProcessor) override
	{
		Super::UpdateDeltaProcessor(InDeltaProcessor);
		const auto& Impact = ActorState.PhysicsState.Impacts;
		if(Impact.UpImpact.bBlockingHit || Impact.ForwardImpact.bBlockingHit || !Impact.DownImpact.bBlockingHit)
		{
			// If we have impacts, we need to sweep expensive until we dont have them.
			// The same goes for not having ground since we expect to always have that
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
			CollisionCheckDeltaInternal(MoveQuery, SolverState, 0);
		}
		// The remote side will always be where the controlside tells it to be
		else if(SolverState.RemainingTime > 0)
		{	
			SolverState.AdvanceDeltaAndLocation(SolverState.RemainingTime);
		}

		FCollisionSolverOutput Output;
		Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
		Output.PhysicalMove.RequestedVelocity = SolverState.CurrentVelocity;
		Output.PhysicsState = SolverState.PhysicsState;

		return Output;
	}

	void CollisionCheckDeltaInternal(const FCollisionMoveQuery& MoveQuery, FCollisionSolverState& SolverState, int Iteration) const
	{
		// We are stuck somehow
		if(Iteration >= MaxIterations)
		{
			SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
			PrintError("Invalid movement: " + ActorState.OwningActor + " is stuck", Duration = 0.f);
			return;
		}

		FHazeHitResult DeltaMoveImpact;
		bool bFoundCollision = false;
		FVector CurrentWorldUp = ActorState.WorldUp;

		// If we are standing in a slope, we use that ones normal as the world up
		if(ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
			CurrentWorldUp = ActorState.PhysicsState.Impacts.DownImpact.Normal;

		const FVector OriginalMoveDirection = SolverState.RemainingDelta.GetSafeNormal();
		
		bool bDoGroundTest = true;
		if(!OriginalMoveDirection.IsNearlyZero())
		{
			const float VerticalMoveDirection = OriginalMoveDirection.DotProduct(ActorState.WorldUp);
			const bool bAirMove = FMath::Abs(VerticalMoveDirection) > KINDA_SMALL_NUMBER || ActorState.PhysicsState.GroundedState != EHazeGroundedState::Grounded;
			

			// We have verical movement so we need to do an expensive sweep
			if(bAirMove)
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
				FMovementQueryParams DeltaMoveShapeTraceParams;
				DeltaMoveShapeTraceParams.From = SolverState.CurrentLocation;
				DeltaMoveShapeTraceParams.To = DeltaMoveShapeTraceParams.From + SolverState.RemainingDelta;
				bFoundCollision = ShapeTracer.CollisionSweep(DeltaMoveShapeTraceParams, DeltaMoveImpact);
				bDoGroundTest = VerticalMoveDirection <= 0.f;
				if(!bFoundCollision)
				{
					SolverState.AdvanceDeltaAndLocation(SolverState.RemainingTime);
				}
				else if(DeltaMoveImpact.bStartPenetrating)
				{
					// We are stuck inside something and need to get out
					// The ai will not do anything more this frame if we are stuck
					HandleSweepWasStartPenetrating(SolverState.CurrentLocation, DeltaMoveImpact);
					CollisionCheckDeltaInternal(MoveQuery, SolverState, Iteration + 1);
					return;
				}
				else
				{
					// Advance the delta and update the impacts
					UpdateLocationFromHit(SolverState, DeltaMoveImpact);
					SolverState.AdvanceDelta(SolverState.RemainingTime * DeltaMoveImpact.Time);
					SetImpactType(SolverState, DeltaMoveImpact);
				}
			}
			else 
			{
				FVector From = SolverState.CurrentLocation;

				// We increase the stepup from the start so we can avoid all the growel in the ground
				From += ActorState.WorldUp * ActorState.StepUpAmount;
				
				FVector RemainingDelta = SolverState.RemainingDelta;
				if(ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
				{
					// Follow the slope if we are standing on one	
					const float MoveAmount = RemainingDelta.Size();
					RemainingDelta = Math::ConstrainVectorToSlope(RemainingDelta, ActorState.PhysicsState.Impacts.DownImpact.Normal, ActorState.WorldUp).GetSafeNormal() * MoveAmount;
				}
		
				FVector To = From + RemainingDelta;
				if(SweepIteration == 0)
				{
					// We only do a expensive trace from time to time to validate that we are not inside anything
					FMovementQueryParams DeltaMoveShapeTraceParams;
					DeltaMoveShapeTraceParams.From = From;
					DeltaMoveShapeTraceParams.To = To;
					bFoundCollision = ShapeTracer.CollisionSweep(DeltaMoveShapeTraceParams, DeltaMoveImpact);
				}
				else if(SweepIteration == 1)
				{
					// Most of the time, we will just do a line trace since we assume that we can move to the grounded location
					FMovementQueryLineParams DeltaMoveLineTraceParams;

					// We increase the from with the capsule radius so we dont trace inside the enemy
					const FVector MoveDirection = RemainingDelta.GetSafeNormal();
					const FCollisionShape& Shape = ShapeTracer.GetCollisionShape();
					const float HorizontalAlpha = 1.f - FMath::Abs(MoveDirection.DotProduct(ActorState.WorldUp));
					From += MoveDirection * (HorizontalAlpha * Shape.GetCapsuleRadius());

					DeltaMoveLineTraceParams.From = From;
					DeltaMoveLineTraceParams.To = To;
					bFoundCollision = ShapeTracer.LineTest(DeltaMoveLineTraceParams, DeltaMoveImpact);
				}

				if(!bFoundCollision)
				{
					// Nothing in the way, so we can move the entire distance
					SolverState.AdvanceDeltaAndLocation(SolverState.RemainingTime, RemainingDelta);
				}
				else if(DeltaMoveImpact.bStartPenetrating)
				{
					// We are stuck inside something and need to get out
					// The ai will not do anything more this frame if we are stuck
					HandleSweepWasStartPenetrating(SolverState.CurrentLocation, DeltaMoveImpact);
					CollisionCheckDeltaInternal(MoveQuery, SolverState, Iteration + 1);
					return;
				}
				else
				{
					// We have a collision
					UpdateLocationFromHit(SolverState, DeltaMoveImpact);
					SolverState.AdvanceDelta(SolverState.RemainingTime * DeltaMoveImpact.Time);
					SetImpactType(SolverState,DeltaMoveImpact);
				}
			}
		}

		if(bDoGroundTest)
		{
			// GroundTrace
			FHazeHitResult GroundTraceImpact;
			if(LineTraceStepDown(SolverState.CurrentLocation, GroundTraceImpact, ActorState.StepUpAmount))
			{
				SolverState.SetHit(EImpactSurfaceType::Ground, GroundTraceImpact);
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;

				// Sometimes, we need to do a shapetrace to find the correct location where we can stand
				if(SweepIteration == 3)
				{
					FVector WantedGroundLocation = GroundTraceImpact.ImpactPoint;
					if(ShapeTraceStepDown(SolverState.CurrentLocation, GroundTraceImpact, ActorState.StepUpAmount))
					{
						FVector DeltaToGround = (WantedGroundLocation - SolverState.CurrentLocation) * GroundTraceImpact.Time;
						SolverState.CurrentLocation += DeltaToGround;
					}		
				}
			}
			else if(IsHitSurfaceWalkable(DeltaMoveImpact))
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
			}
			else
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
			}
		}
	}

	void SetImpactType(FCollisionSolverState& SolverState, FHazeHitResult Impact) const
	{
		const float ImpactAlpha = Impact.Normal.DotProduct(ActorState.WorldUp); 
		if(ImpactAlpha < -0.2f)
		{
			// We have hit something that counts as a ceiling
			SolverState.SetHit(EImpactSurfaceType::Ceiling, Impact);
		}
		else if(!IsHitSurfaceWalkable(Impact))
		{
			// We cant stand at the current impact, so its a wall
			SolverState.SetHit(EImpactSurfaceType::Wall, Impact);
		}
		else
		{
			// We have hit the ground
			SolverState.SetHit(EImpactSurfaceType::Ground, Impact);
		}
	}
};
