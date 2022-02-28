namespace PickupTags
{
	// General
	const FName PickupSystem = n"Pickups";

	// Pickup
	const FName PickupCapability = n"PickupCapability";

	// Putdown
	const FName PutdownCapability = n"PickupPutdownCapability";
	const FName PutdownStarterCapability = n"PickupPutdownStarterCapability";

	const FName PutdownGroundCapability = n"PickupPutdownGroundCapability";
	const FName PutdownGroundInPlaceCapability = n"PickupPutdownGroundInPlaceCapability";

	const FName PutdownAirCapability = n"PickupPutdownAirCapability";
	const FName PutdownTeleportCapability = n"PickupPutdownTeleportCapability";
	const FName PutdownCancelledCapability = n"PickupPutdownCancelledCapability";
	const FName PutdownOnPointCapability = n"PickupPutdownOnPointCapability";
	const FName PutdownTargetObject = n"PickupPutdownTargetObject";

	// Putdown - on pickup actor
	const FName PickupGroundPutdownCapability = n"PickupGroundPutdownCapability";
	const FName PickupGroundPutdown = n"PickupGroundPutdownAS";
	const FName PickupGroundPutdownLocation = n"PickupGroundPutdownLocationAS";
	const FName PickupGroundPutdownRotationOverride = n"PickupGroudnPutdownRotationOverrideAS";

	// Throwing
	const FName PickupAimCapability = n"PickupAimCapability";
	const FName PickupConstrainedAimCapability = n"PickupConstrainedAimCapability";
	const FName PickupAimAnimationRequestCapability = n"PickupAimAnimationRequestCapability";
	const FName PickupArchedAimCapability = n"PickupArchedAimCapability";
	const FName PickupThrowCapability = n"PickupThrowCapability";

	// Throwing - Action states
	const FName StartPickupConstrainedAim = n"StartPickupConstrainedAimAS";
	const FName PickupConstrainedAimStartForward = n"PickupConstrainedAimStartForward";
	const FName AbortPickupFlight = n"AbortPickupFlightAS";

	// Throwing - on pickup actor
	const FName PickupThrowControlledAirTravelCapability = n"PickupThrowControlledAirTravelCapability";
	const FName PickupThrowUnrealPhysicsCapability = n"PickupThrowUnrealPhysicsCapability";

	// Pickup actor's capabilies - these are held by the pickupable actor
	// Transform lerp stuff
	const FName PickupRotationLerpCapability = n"PickupRotationLerpCapability";
	const FName PickupOffsetLerpCapability = n"PickupOffsetLerpCapability";

	// Bouncing
	const FName PickupableBounceCapability = n"ThrownPickupBounceCapability";
	const FName PickupablePostThrowCollisionEnabler = n"PostThrowCollisionEnablerCapability";

	// Attachment stuff
	const FName PickupFloorAttacherCapability = n"PickupFloorAttacherCapability";

	// Audio
	const FName PickupAudioCapability = n"PickupAudioCapability";
}