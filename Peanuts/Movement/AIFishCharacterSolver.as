
import Peanuts.Movement.CollisionSolver;
import Peanuts.Movement.NoCollisionSolver;


class UAIFishCharacterSolver : UCollisionSolver
{
	void PostSweep(FCollisionSolverState& SolverState) const override
	{
		if (DeltaProcessor != nullptr)
			DeltaProcessor.PostIteration(ActorState, SolverState);
	}
};

class UAIFishCharacterRemoteSolver : UNoCollisionSolver
{

};
