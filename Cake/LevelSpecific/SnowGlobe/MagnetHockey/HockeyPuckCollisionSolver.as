import Peanuts.Movement.CollisionSolver;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;

class UHockeyPuckCollisionSolver : UCollisionSolver
{
	void ProcessImpact(FCollisionSolverState& SolverState, EImpactSurfaceType ImpactType, FHazeHitResult Impact) const
	{
		SolverState.SetHit(ImpactType, Impact);
		
		AHockeyPaddle Paddle = Cast<AHockeyPaddle>(Impact.Actor);

		if (Paddle != nullptr)
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