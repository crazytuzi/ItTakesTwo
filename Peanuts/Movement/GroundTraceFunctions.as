
UFUNCTION(Category = "HazeMovement")
bool IsHitSurfaceWalkableDefault(const FHitResult& SurfaceHit, float MaxWalkableAngle, FVector WorldUp)
{		
	if (!SurfaceHit.bBlockingHit)
		return false;

	if (SurfaceHit.Component == nullptr)
		return false;

	if (!SurfaceHit.Component.HasTag(ComponentTags::Walkable))
		return false;

	float MaxSlopeAngle = FMath::Cos(FMath::DegreesToRadians(MaxWalkableAngle));
	float SurfaceHitAngle = WorldUp.DotProduct(SurfaceHit.ImpactNormal);

	return (SurfaceHitAngle > MaxSlopeAngle);
}

bool IsPlayerGroundedAtLocation(AHazePlayerCharacter Player, FVector Location)
{
	auto MoveComp = Player.MovementComponent;

	FHazeTraceParams FloorTrace;
	FloorTrace.InitWithMovementComponent(MoveComp);
	FloorTrace.UnmarkToTraceWithOriginOffset();
	FloorTrace.InitWithCollisionProfile(n"PlayerCharacter");
	FloorTrace.From = Location;
	FloorTrace.To = FloorTrace.From - MoveComp.WorldUp * MoveComp.GetStepAmount(40.f);

	FHazeHitResult Hit;
	if (!FloorTrace.Trace(Hit))
		return false;
	
	if (!IsHitSurfaceWalkableDefault(Hit.FHitResult, MoveComp.WalkableAngle, MoveComp.WorldUp))
		return false;
	return true;
}