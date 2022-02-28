
// Used to prevent the player from failling of ledges while aiming.

import Peanuts.Movement.DefaultCharacterCollisionSolver;

class UNailAimCollisionSolver : UDefaultCharacterCollisionSolver
{
	UFUNCTION(BlueprintOverride)
	FCollisionSolverOutput CollisionCheckDelta(const FCollisionMoveQuery& MoveQuery) const
	{
		FCollisionSolverOutput Output = Super::CollisionCheckDelta(MoveQuery);

		// Zero the delta move if we are about to walk off a ledge
		if(Output.PhysicsState.GroundedState != EHazeGroundedState::Grounded 
		&& Output.PhysicalMove.MovedDelta.DotProduct(FVector::UpVector) < KINDA_SMALL_NUMBER)
		{
			Output.PhysicsState.GroundedState = EHazeGroundedState::Grounded;
			Output.PhysicalMove.MovedDelta = FVector::ZeroVector;
			Output.PhysicalMove.TeleportedDelta = FVector::ZeroVector;
			Output.PhysicalMove.RequestedVelocity = FVector::ZeroVector;
			Output.PhysicsState.PushData = FPlatformPushData();
		}

		return Output;
	}

}
