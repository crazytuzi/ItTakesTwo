import Peanuts.Movement.AICollisionSolver;

// This solver should be used for AIs who is not going to walk over edges.
// It is optimized for air and relativly flat surfaces
class UAICharacterGroundedDetectionSolverOnlyLineTrace : UAICollisionSolver
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
		if(!SolverState.bLastTraceIncomplete)
		{
			Output.PhysicalMove.MovedDelta = SolverState.MovedDelta;
			Output.PhysicalMove.RequestedVelocity = SolverState.CurrentVelocity;
			Output.PhysicsState = SolverState.PhysicsState;
		}
		else
		{
			PrintError("Invalid movement: " + ActorState.OwningActor + " is stuck", Duration = 0.f);
		}
	
		return Output;
	}

	void CollisionCheckDeltaInternal(const FCollisionMoveQuery& MoveQuery, FCollisionSolverState& SolverState, int Iteration) const
	{
		// We are stuck somehow
		if(Iteration >= MaxIterations)
		{
			SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
			SolverState.MarkIterationAsIncomplete();
			return;
		}

		FHazeHitResult DeltaMoveImpact;
		bool bFoundCollision = false;
		FVector CurrentWorldUp = ActorState.WorldUp;

		// If we are standing in a slope, we use that ones normal as the world up
		if(ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
			CurrentWorldUp = ActorState.PhysicsState.Impacts.DownImpact.Normal;

		const FVector OriginalMoveDirection = SolverState.RemainingDelta.GetSafeNormal();
		
		bool bDoGroundTest = SweepIteration == 0;
		if(!OriginalMoveDirection.IsNearlyZero())
		{
			const float VerticalMoveDirection = OriginalMoveDirection.DotProduct(ActorState.WorldUp);
			const bool bAirMove = FMath::Abs(VerticalMoveDirection) > KINDA_SMALL_NUMBER || ActorState.PhysicsState.GroundedState != EHazeGroundedState::Grounded;
			

			// We have verical movement so we need to do an expensive sweep
			if(bAirMove)
			{
				SolverState.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
				FMovementQueryLineParams DeltaMoveShapeTraceParams;
				DeltaMoveShapeTraceParams.From = SolverState.CurrentLocation;
				DeltaMoveShapeTraceParams.To = DeltaMoveShapeTraceParams.From + SolverState.RemainingDelta;
				bFoundCollision = ShapeTracer.LineTest(DeltaMoveShapeTraceParams, DeltaMoveImpact);
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
				const FCollisionShape& Shape = ShapeTracer.GetCollisionShape();
				FVector From = SolverState.CurrentLocation;
				From += ActorState.WorldUp * Shape.GetCapsuleHalfHeight();

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

				// We increase the trace distance with the capsule radius
				if(!RemainingDelta.IsNearlyZero())
				{
					
					To += RemainingDelta.GetSafeNormal() * (Shape.GetCapsuleRadius());
				}

				FMovementQueryLineParams DeltaMoveShapeTraceParams;
				DeltaMoveShapeTraceParams.From = From;
				DeltaMoveShapeTraceParams.To = To;
				bFoundCollision = ShapeTracer.LineTest(DeltaMoveShapeTraceParams, DeltaMoveImpact);
		
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

				FVector WantedGroundLocation = GroundTraceImpact.ImpactPoint;
				FVector DeltaToGround = (WantedGroundLocation - SolverState.CurrentLocation) * GroundTraceImpact.Time;
				SolverState.CurrentLocation += DeltaToGround;
				SolverState.CurrentLocation += FVector::UpVector;
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

	bool HandleSweepWasStartPenetrating(FVector& CurrentLocation, FHazeHitResult Overlap) const override
	{
		FVector MoveDir = (Overlap.GetTraceEnd() - Overlap.GetTraceStart()).GetSafeNormal();
		if(MoveDir.IsNearlyZero())
			MoveDir = ActorState.OwningActor.GetActorForwardVector();
		
		const FCollisionShape& Shape = ShapeTracer.GetCollisionShape();
		CurrentLocation -= MoveDir * Shape.GetCapsuleRadius();
		return true;
	}

	void UpdateLocationFromHit(FCollisionSolverState& State, FHazeHitResult Hit) const override
	{
		const EImpactSurfaceType SurfaceType = GetSurfaceTypeFromHit(Hit);
		State.CurrentLocation += GetPullbackAmount(Hit, SurfaceType);
	}

	FVector GetPullbackAmount(FHazeHitResult Hit, EImpactSurfaceType ImpactType) const override
	{
		if (ImpactType == EImpactSurfaceType::Ground)
		{
			return ActorState.WorldUp * 0.2f;
		}
		else
		{
			return Hit.Normal.ConstrainToPlane(ActorState.WorldUp).SafeNormal;
		}
	}
};
