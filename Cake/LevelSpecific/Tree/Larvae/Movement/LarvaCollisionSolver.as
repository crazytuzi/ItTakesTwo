#if TEST
const FConsoleVariable CVar_LarvaSolverTraceInterval("Haze.LarvaSolverTraceInterval", 1);
#endif

// Larvae will normally operate in a nav mesh, so will usually always be able to move
// freely in horizontal space and will slide up/down along the ground otherwise.
// In addition, there are no edges to fall off in the larva combat area.
class ULarvaCollisionSolver : UHazeCollisionSolver
{
	UCapsuleComponent CollisionComp;
	FHazeAcceleratedFloat TargetHeight;

	UFUNCTION(BlueprintOverride)
	void OnCreated(AHazeActor OwningActor)
	{
		CollisionComp = UCapsuleComponent::Get(OwningActor);
	}

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
		// Where do we want to go today? Note that this includes gravity.
		FVector Destination = MoveQuery.Location + MoveQuery.Delta;
		FCollisionSolverOutput Output;

		// Don't do anything if we don't want to move when on ground
		bool bIsFalling = (ActorState.PhysicsState.GroundedState != EHazeGroundedState::Grounded);
		if (!bIsFalling && MoveQuery.Delta.IsNearlyZero())
		{
			Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
			Output.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;
			Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
			Output.PhysicalMove.RequestedVelocity.Z = 0.f;	
			return Output;
		}

		// Every few frames we check for ground. Since we're squishy and move fairly slowly 
		// we don't care that we might clip through the ground a bit.
		FHazeHitResult DownHit;
		int TraceInterval = 1;
#if TEST
		TraceInterval = FMath::Max(1, CVar_LarvaSolverTraceInterval.Int);
#endif		
		if (bIsFalling || ((GFrameNumber % TraceInterval) == (ActorState.OwningActor.Name.Hash % TraceInterval)))
		{
			float ZOffset = FMath::Max(10.f, 600.f * MoveQuery.DeltaTime);
			FVector Above = FVector(Destination.X, Destination.Y , FMath::Max(MoveQuery.Location.Z + ZOffset, Destination.Z) - CollisionComp.ScaledCapsuleHalfHeight);
			FVector Below = FVector(Destination.X, Destination.Y , FMath::Min(MoveQuery.Location.Z - ZOffset, Destination.Z) - CollisionComp.ScaledCapsuleHalfHeight);
#if EDITOR
			//CollisionComp.bHazeEditorOnlyDebugBool = true;
			if (CollisionComp.bHazeEditorOnlyDebugBool)
				System::DrawDebugLine(Above, Below, FLinearColor::Green);
#endif
			if (ShapeTracer.LineTest(Above, Below, DownHit))
			{
				// Found ground, slide along
				Destination.Z = DownHit.ShapeLocation.Z;
				Destination.Z += CollisionComp.ScaledCapsuleHalfHeight;
			}
			else
			{
				// Did not find ground, fall down with air control (this should only rarely happen)
				Output.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
				Output.PhysicalMove.MovedDelta = Destination - MoveQuery.Location;
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
				return Output;
			}
		}
		else
		{
		 	// Skip trace and use previous ground
		 	DownHit.OverrideFHitResult(ActorState.PhysicsState.Impacts.DownImpact);
			
			// Do not allow falling when defaulting movement like this, or we may tunnel through ground!
			Destination.Z = MoveQuery.Location.Z;
		}

		Output.PhysicalMove.MovedDelta = Destination - MoveQuery.Location;
		Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
		Output.PhysicalMove.RequestedVelocity.Z = 0.f;
		Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
		Output.PhysicsState.Impacts.DownImpact = DownHit.FHitResult;
		return Output;
	}
};
