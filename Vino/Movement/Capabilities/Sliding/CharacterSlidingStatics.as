import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;

// Returns a normalized vector in the direction down the slope
FVector GetSlopeDirection(FVector Normal, FVector WorldUp)
{
	FVector BiNormal = Normal.CrossProduct(WorldUp);
	return Normal.CrossProduct(BiNormal).GetSafeNormal();
}

// Returns the angle in degrees of the steepness of the slope
float GetSlopeAngle(FVector SlopeNormal, FVector WorldUp)
{
	FVector SlopeDirection = GetSlopeDirection(SlopeNormal, WorldUp);		

	return FMath::Asin(SlopeDirection.DotProduct(-WorldUp)) * RAD_TO_DEG;
}

// Returns the angle in degrees of the effective slope angle, based on velocity
float GetEffectiveSlopeAngle(FVector SlopeNormal, FVector WorldUp, FVector Velocity)
{
	FVector SlopeDirection = Velocity.GetSafeNormal();

	FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);

	if (HorizontalVelocity.IsNearlyZero())
		SlopeDirection = GetSlopeDirection(SlopeNormal, WorldUp);

	float ActualAngle = FMath::Asin(SlopeDirection.DotProduct(WorldUp)) * RAD_TO_DEG;

	return ActualAngle; 
}

// Used in Slidng and Crouching to test whether you can stand in a location or not
bool CheckPlayerCapsuleHit(AHazePlayerCharacter Player, float OverrideCapsuleHalfHeight = -1.f, float DebugDrawTime = -1.f)
{
	FVector WorldUp = Player.MovementWorldUp;

	float CapsuleHalfHeight = Player.CapsuleComponent.CapsuleHalfHeight;
	if (OverrideCapsuleHalfHeight > 0.f)
		CapsuleHalfHeight = OverrideCapsuleHalfHeight;
		
	float CapsuleRadius = Player.CapsuleComponent.CapsuleRadius;
	FVector OverlapLocation = Player.ActorLocation + (WorldUp * CapsuleHalfHeight);

	FHazeTraceParams TraceParams;	
	TraceParams.InitWithCollisionProfile(n"PlayerCharacter");
	TraceParams.ShapeRotation = Player.CapsuleComponent.WorldRotation.Quaternion();
	TraceParams.SetToCapsule(CapsuleRadius, CapsuleHalfHeight);
	TraceParams.SetOverlapLocation(OverlapLocation);
	TraceParams.DebugDrawTime = DebugDrawTime;

	TArray<FOverlapResult> OutOverlaps;

	return TraceParams.Overlap(OutOverlaps);
}