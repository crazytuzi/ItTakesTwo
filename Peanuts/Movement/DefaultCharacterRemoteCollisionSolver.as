import Peanuts.Movement.DefaultCharacterCollisionSolver;

const FStatID STAT_CharacterRemoteSolver(n"CharacterRemoteSolver");

class UDefaultCharacterRemoteCollisionSolver : UDefaultCharacterCollisionSolver
{
	const int MaxIteraction = 3;

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
#if TEST
		FScopeCycleCounter Counter(STAT_CharacterRemoteSolver);
#endif

		if(!MoveQuery.bCrumbRequest)
			return Super::CollisionCheckDelta(MoveQuery);

		FCollisionSolverOutput OutData;

		FVector WantedLocation =  MoveQuery.Location + MoveQuery.Delta;
		float TraceUpAmount = FMath::Max(ActorState.StepUpAmount, 10.f);
		float TraceDownAmount = FMath::Max(ActorState.StepDownAmount, 10.f);

		FVector TraceFrom = WantedLocation + (ActorState.WorldUp * TraceUpAmount);
		FVector TraceTo = WantedLocation - (ActorState.WorldUp * TraceDownAmount);

		OutData.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
		FHazeHitResult GroundTrace;
		ShapeTracer.CollisionSweep(TraceFrom, TraceTo, GroundTrace);
		if(GroundTrace.bBlockingHit && !GroundTrace.bStartPenetrating)
		{
			OutData.PhysicalMove.MovedDelta = MoveQuery.Delta.ConstrainToPlane(ActorState.WorldUp);
			OutData.PhysicsState.Impacts.DownImpact = GroundTrace.FHitResult;
			if(IsHitSurfaceWalkableDefault(GroundTrace.FHitResult, ActorState.WalkableSlopeAngle, ActorState.WorldUp))
				OutData.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
	
			FVector ImpactLocation =  GroundTrace.ActorLocation;
			
			FVector TracedVertivalDelta = (ImpactLocation - MoveQuery.Location).ConstrainToDirection(ActorState.WorldUp);
			FVector OriginalVerticalDelta = MoveQuery.Delta.ConstrainToDirection(ActorState.WorldUp);
			if ((TracedVertivalDelta - OriginalVerticalDelta).SizeSquared() > 1.f)
				OutData.PhysicalMove.MovedDelta += TracedVertivalDelta;
			else
				OutData.PhysicalMove.MovedDelta += OriginalVerticalDelta;
		}
		else
		{
			// Handling of missing down impacts when character capsule was scaled for crouching, needed for audio
			TraceFrom =  WantedLocation + (ActorState.WorldUp * 10.f);
			TraceTo = WantedLocation - (ActorState.WorldUp * 10.f);

			OutData.PhysicalMove.MovedDelta = MoveQuery.Delta;
			ShapeTracer.LineTest(TraceFrom, TraceTo, GroundTrace);	
			OutData.PhysicsState.Impacts.DownImpact = GroundTrace.FHitResult;		
		}

		// We always apply the wanted velocity
		OutData.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
		return OutData;
	}
};
