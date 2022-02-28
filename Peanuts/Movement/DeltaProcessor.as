import Peanuts.Movement.CollisionData;
import Peanuts.Movement.MovementDebugDataComponent;

class UDeltaProcessor : UHazeDeltaProcessorBase
{
#if EDITOR
	UMovementDebugDataComponent DebugComp = nullptr;
#endif

	void ImpactCorrection(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult& Impact) {};

	void OnDepentrated(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FDepenetrationOutput DepenetrationOutput) {};

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTimeStep) {};

	void PostIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState) {};

	bool HandleDepenetration(FCollisionSolverActorState ActorState, FCollisionSolverState SolverState, UHazeShapeTracer ShapeTracer, FHazeHitResult Hit, FDepenetrationOutput& OutDepen) { return false; };
}
