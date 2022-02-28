/**
 * An *extremely* minimal collision solver for enemies.
 * Basically only does one or two line traces for movement, meaning:
 * - NO velocity redirect of any kind.
 * - NO depenetration of any kind.
 * - Character capsule can EASILY partially overlap things.
 * - Walking of edges can 
 */
class UMinimalAICharacterSolver : UHazeCollisionSolver
{
	bool bCheckFloorCollision = true;

	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
		FVector FlatDelta = MoveQuery.Delta;
		FlatDelta.Z = 0.f;

		FVector TargetLocation = MoveQuery.Location;

		// Don't do anything if not moving and on a static floor
		if (FlatDelta.IsNearlyZero() && ActorState.PhysicsState.GroundedState == EHazeGroundedState::Grounded)
		{
			if (CanAvoidCalculatingMovement())
			{
				FCollisionSolverOutput Output;
				Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				Output.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
				return Output;
			}
		}

		// If we are not grounded, or every few frames, test downward
		bool bCheckDown = false;
		if (ActorState.PhysicsState.GroundedState != EHazeGroundedState::Grounded)
			bCheckDown = true;
		if ((GFrameNumber % 3) == (ActorState.OwningActor.Name.Hash % 3))
			bCheckDown = true;

		FHazeHitResult DownHit;
		if (bCheckDown && bCheckFloorCollision)
		{
			if (ShapeTracer.LineTest(
				MoveQuery.Location + FVector(0.f, 0.f, 10.f),
				MoveQuery.Location + FVector(0.f, 0.f, FMath::Min(-10.f, MoveQuery.Delta.Z)), DownHit))
			{
				if (!DownHit.bStartPenetrating)
				{
					// Do a very simple stepdown if we can. We don't even give a shit about penetration here
					float VerticalDistance = FMath::Abs(DownHit.ActorLocation.Z - MoveQuery.Location.Z);
					if (VerticalDistance < 20.f)
					{
						// Continue with the rest of the movement
						TargetLocation.Z = DownHit.ActorLocation.Z;
					}
					else
					{
						// Go into falling mode!
						TargetLocation.Z = FMath::Max(
							MoveQuery.Location.Z + FMath::Min(MoveQuery.Delta.Z, 0.f),
							DownHit.ActorLocation.Z
						);

						FCollisionSolverOutput Output;
						Output.PhysicalMove.MovedDelta = TargetLocation - MoveQuery.Location;
						Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
						Output.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
						return Output;
					}
				}
			}
			else
			{
				// We are falling, only apply vertical velocity now!
				TargetLocation.Z += FMath::Min(MoveQuery.Delta.Z, 0.f);

				FCollisionSolverOutput Output;
				Output.PhysicalMove.MovedDelta = TargetLocation - MoveQuery.Location;
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
				Output.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
				return Output;
			}
		}
		else
		{
			DownHit.OverrideFHitResult(ActorState.PhysicsState.Impacts.DownImpact);
		}

		// Do one single sweep for our horizontal movement
		FHazeHitResult ForwardHit;
		if (!FlatDelta.IsNearlyZero())
		{
			FVector HoverAmount(0.f, 0.f, 20.f);
			if (ShapeTracer.CollisionSweep(
				MoveQuery.Location + HoverAmount,
				TargetLocation + FlatDelta + HoverAmount,
				ForwardHit))
			{
				// Allow a very small depenetration
				if (ForwardHit.bStartPenetrating && ForwardHit.PenetrationDepth < 1.f)
				{
					FCollisionSolverOutput Output;
					Output.PhysicalMove.MovedDelta = ForwardHit.ImpactNormal.GetSafeNormal2D() * (ForwardHit.PenetrationDepth + 0.01f);
					Output.PhysicalMove.RequestedVelocity = FVector::ZeroVector;
					Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
					Output.PhysicsState.Impacts.ForwardImpact = ForwardHit.FHitResult;
					return Output;
				}

				// Try to move the maximum amount we can
				FVector DeltaDirection = FlatDelta.GetSafeNormal();
				float TotalDistance = FlatDelta.Size();
				float PossibleDistance = TargetLocation.Distance(ForwardHit.ActorLocation - HoverAmount);

				if (PossibleDistance < 0.f)
				{
					FCollisionSolverOutput Output;
					Output.PhysicalMove.MovedDelta = FVector::ZeroVector;
					Output.PhysicalMove.RequestedVelocity = FVector::ZeroVector;
					Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
					Output.PhysicsState.Impacts.ForwardImpact = ForwardHit.FHitResult;
					return Output;
				}

				// Pull back somewhat from the hit so we avoid penetration
				TargetLocation += (DeltaDirection * FMath::Max(PossibleDistance - 0.1f, 0.f));

				FCollisionSolverOutput Output;
				Output.PhysicalMove.MovedDelta = TargetLocation - MoveQuery.Location;
				Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
				Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
				Output.PhysicsState.Impacts.ForwardImpact = ForwardHit.FHitResult;
				Output.PhysicsState.Impacts.DownImpact = ActorState.PhysicsState.Impacts.DownImpact;
				return Output;
			}
		}

		// No hits during the forward move, so we can move forward properly
		TargetLocation += FlatDelta;

		FCollisionSolverOutput Output;
		Output.PhysicalMove.MovedDelta = TargetLocation - MoveQuery.Location;
		Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
		Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
		Output.PhysicsState.Impacts.DownImpact = DownHit.FHitResult;
		Output.PhysicsState.Impacts.ForwardImpact = ForwardHit.FHitResult;
		return Output;
	}

	bool CanAvoidCalculatingMovement() const
	{
		UPrimitiveComponent CurrentFloor = ActorState.CurrentFloor;

		if (CurrentFloor == nullptr)
		{
			if (!ActorState.PhysicsState.Impacts.DownImpact.bBlockingHit)
				return false;
			CurrentFloor = ActorState.PhysicsState.Impacts.DownImpact.Component;
		}

		if (CurrentFloor != nullptr && CurrentFloor.Mobility == EComponentMobility::Static)
			return true;

		return false;
	}
};

class URemoteMinimalAICharacterSolver : UMinimalAICharacterSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
		if(!MoveQuery.bCrumbRequest)
			return Super::CollisionCheckDelta(MoveQuery);

		// If we are not grounded, or every few frames, test downward
		bool bCheckDown = false;
		if (ActorState.PhysicsState.GroundedState != EHazeGroundedState::Grounded)
			bCheckDown = true;
		if ((GFrameNumber % 3) == (ActorState.OwningActor.Name.Hash % 3))
			bCheckDown = true;

		FCollisionSolverOutput Output;
		Output.PhysicsState.GroundedState = ActorState.PhysicsState.GroundedState;

		FHazeHitResult DownHit;
		if (bCheckDown && bCheckFloorCollision)
		{
			if (ShapeTracer.LineTest(
				MoveQuery.Location + FVector(0.f, 0.f, 10.f),
				MoveQuery.Location + FVector(0.f, 0.f, FMath::Min(-10.f, MoveQuery.Delta.Z)), DownHit))
			{
				if (!DownHit.bStartPenetrating)
				{
					// Do a very simple stepdown if we can. We don't even give a shit about penetration here
					float VerticalDistance = FMath::Abs(DownHit.ActorLocation.Z - MoveQuery.Location.Z);
					if (VerticalDistance >= 20.f)
						Output.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
				}
			}
			else
			{
				Output.PhysicsState.GroundedState = EHazeGroundedState::Airborne;
			}
		}
		else
		{
			DownHit.OverrideFHitResult(ActorState.PhysicsState.Impacts.DownImpact);
		}

		Output.PhysicalMove.MovedDelta = MoveQuery.Delta;
		Output.PhysicalMove.RequestedVelocity = MoveQuery.Velocity;
		Output.PhysicsState.Impacts.DownImpact = DownHit.FHitResult;
		return Output;
	}
};