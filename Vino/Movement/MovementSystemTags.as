namespace MovementSystemTags
{
    const FName GroundMovement = n"GroundMovement";
    const FName AirMovement = n"AirMovement";
    const FName BasicFloorMovement = n"BasicFloorMovement";
  
    const FName Falling = n"Falling";
    const FName SkyDive = n"SkyDive";
    const FName LedgeGrab = n"LedgeGrab";
	const FName LedgeVault = n"LedgeVault";
	const FName LedgeNodes = n"LedgeNodeTraversal";
    const FName LedgeGrabJump = n"LedgeGrabJump";
    const FName Jump = n"Jump";
	const FName FloorJump = n"FloorJump";
	const FName AirJump = n"AirJump";
    const FName Dash = n"Dash";
	const FName AirDash = n"AirDash";
    const FName Crouch = n"Crouch";
    const FName Sliding = n"Sliding";
    const FName Sprint = n"Sprint";
	const FName Swimming = n"Swimming";
	const FName Swinging = n"Swinging";
    const FName LandingStun = n"LandingStun";
    const FName WallRun = n"WallRun";
    const FName WallSlide = n"WallSlide";
    const FName WallSlideJump = n"WallSlideJump";
	const FName WallSlideEvaluation = n"WallSlideEvaluation";
    const FName SlopeSlide = n"SlopeSlide";
    const FName SplineSlide = n"SplineSlide";
    const FName GroundPound = n"GroundPound";
    const FName Grinding = n"Grinding";
    const FName PhysicsForce = n"PhysicsForce";
	const FName TurnAround = n"TurnAround";
	const FName AudioMovementEfforts = n"AudioMovementEfforts";
	const FName DoublePull = n"DoublePull";

	// This is used in the movement debug menu.
	// Any added category here will show up in the movement debug menu
	UFUNCTION(BlueprintPure)
	TArray<FName> GetAllMovementTags()
	{
		TArray<FName> OutParams;

		OutParams.Add(GroundMovement);
		OutParams.Add(AirMovement);
		OutParams.Add(BasicFloorMovement);

		OutParams.Add(SkyDive);
		OutParams.Add(Falling);
		OutParams.Add(LedgeGrab);
		OutParams.Add(LedgeVault);
		OutParams.Add(LedgeGrabJump);
		OutParams.Add(Jump);
		OutParams.Add(Dash);
		OutParams.Add(AirDash);
		OutParams.Add(Sprint);
		OutParams.Add(Swimming);		
		OutParams.Add(Swinging);
		OutParams.Add(Crouch);
		OutParams.Add(LandingStun);
		OutParams.Add(WallRun);
		OutParams.Add(WallSlide);
		OutParams.Add(SlopeSlide);
		OutParams.Add(GroundPound);
		OutParams.Add(Grinding);
		OutParams.Add(PhysicsForce);
		OutParams.Add(TurnAround);
		
		return OutParams;
	}
}

namespace MovementActivationEvents
{
	const FName Airbourne = n"AirbourneMovementEvent";
	const FName Grounded = n"GroundedMovementEvent";

	const FName SkyDiving = n"SkyDivingActiveMovementEvent";
}
