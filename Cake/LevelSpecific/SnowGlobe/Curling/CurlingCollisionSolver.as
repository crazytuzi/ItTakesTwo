import Peanuts.Movement.CollisionSolver;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingObstacle;

class UCurlingCollisionSolver : UCollisionSolver
{
	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		SolverState.SetHit(ImpactType, Impact);
		
		ACurlingStone OtherStone = Cast<ACurlingStone>(Impact.Actor);
		ACurlingObstacle CurlingObstacle = Cast<ACurlingObstacle>(Impact.Actor);

		//WHAT ARE WE COLLIDING WITH?
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Impact.Actor);

		if (OtherStone != nullptr || CurlingObstacle != nullptr || Impact.Actor.ActorHasTag(n"CurlingWalls"))
		{
			SolverState.RemainingTime = 0.f;
			return;
		}

		FCollisionRedirectInput Redirect;
		Redirect.Method = EDeltaRedirectMethod::PlaneProject;
		Redirect.RedirectNormal = Impact.Normal;
		Redirect.Impact = Impact;
	
		SolverState.bVelocityIsDirty = true;

		RedirectImpact(SolverState, ImpactType, Redirect);
	}
}