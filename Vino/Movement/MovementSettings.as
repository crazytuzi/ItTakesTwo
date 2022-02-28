/*
*	Constains helper variabels for calculating movement. These values are not locked in stone and several capabilites will set its own custom values.
*	But these variables are useful to get consistency across multiple movement capabilities.
*/

UCLASS(meta=(ComposeSettingsOnto = "UMovementSettings"))
class UMovementSettings : UHazeComposableSettings
{
	// How many units per second the actor should move in when at full speed.
	UPROPERTY()
	float MoveSpeed = 400.f;

	// How many units per second the actor should move horizontally while in the air
	UPROPERTY()
	float HorizontalAirSpeed = 800.f;

	// How much we multiply the levels gravity when applying it to the actor.
	UPROPERTY()
	float GravityMultiplier = 3.f;

	// Set what value we should clamp downwards velocity to.
	UPROPERTY()
	float ActorMaxFallSpeed = 1800.f;

	// How much the actor will normally step or down.
	UPROPERTY()
	float StepUpAmount = 40.f;

	// Surfaces with a lower angle than this (normal pointing straight down is 0 degrees), are considered ceilings
	UPROPERTY()
	float CeilingAngle = 20.f;

	// If angle to the surface hit when moving forwards is higher then the WalkableSlopeAngle then the actor will be blocked, otherwise the actor will slide up it and be allowed to stand on it.
	UPROPERTY()
	float WalkableSlopeAngle = 55.f;

	// How fast the actor will accelerate towards its wanted value while in the air.
	UPROPERTY()
	float AirControlLerpSpeed = 2500.f;
    
	// How fast the character will turn in radians per second while on the ground.
	UPROPERTY()
	float GroundRotationSpeed = 12.f;
    
	// How fast the character will turn in radians per second while in the air.
	UPROPERTY()
	float AirRotationSpeed = 20.f;
	
	// How much velocity/force upwards the actor must have to leave the ground.
	UPROPERTY()
	float VerticalForceAirPushOffThreshold = 500.f;
}
