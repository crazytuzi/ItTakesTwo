import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledTags;
import Peanuts.Movement.DefaultCharacterCollisionSolver;

class UBoatsledCollisionSolver : UDefaultCharacterCollisionSolver
{
	EImpactSurfaceType GetSurfaceTypeFromHit(FHazeHitResult HitResult) const override
	{
		if (IsBoatsledTrackBarrier(HitResult.Component))
			return EImpactSurfaceType::Wall;

		// This will refrain boatsled from colliding with a track seam
		if (IsBoatsledTrack(HitResult.Component))
			return EImpactSurfaceType::Ground;

		return Super::GetSurfaceTypeFromHit(HitResult);
	}

	bool IsHitSurfaceWalkable(FCollisionSolverState SolverState, FHazeHitResult Hit) const override
	{
		if(!IsBoatsledTrack(Hit.Component))
			return false;

		return Super::IsHitSurfaceWalkable(SolverState, Hit);
	}

	bool IsBoatsledTrack(const UPrimitiveComponent& HitComponent) const
	{
		if (HitComponent == nullptr)
			return false;

		return HitComponent.HasTag(BoatsledTags::BoatsledTrackActorTag);
	}

	bool IsBoatsledTrackBarrier(const UPrimitiveComponent& HitComponent) const
	{
		if (HitComponent == nullptr)
			return false;
		
		return HitComponent.HasTag(BoatsledTags::BoatsledCollisionBarrierActorTag);
	}
}