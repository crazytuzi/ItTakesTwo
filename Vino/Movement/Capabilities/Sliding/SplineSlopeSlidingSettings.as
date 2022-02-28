// Normal sliding and jumping have different turn speeds
UCLASS(meta=(ComposeSettingsOnto = "USplineSlopeSlidingTurnSettings"))
class USplineSlopeSlidingTurnSettings : UHazeComposableSettings
{
	// Max speed we can reach on the splines right vector.
	UPROPERTY()
	float MaxSideSpeed = 2000.f;

	// How fast the character reaches Max side speed.
	UPROPERTY()
	float DefaultSideAccelerationTime = 4.5f;

	// How fast it takes to turn while our velocity is in the OppositeDirection of inputdirection.
	UPROPERTY()
	float SteeringTowardsOppositeSideAccelerationTime = 3.0f;
}

// Normal sliding and jumping have different turn speeds
UCLASS(meta=(ComposeSettingsOnto = "USplineSlopeSlidingForwardSpeedSettings"))
class USplineSlopeSlidingForwardSpeedSettings : UHazeComposableSettings
{
	// Max speed we can reach on the splines right vector.
	UPROPERTY()
	float MaxForwardSpeed = 2500.f;

	UPROPERTY()
	float NeutralSpeed = 2500.f;

	UPROPERTY()
	float MinForwardSpeed = 2500.f;

	// How fast the character reaches Max speed.
	UPROPERTY()
	float AccelerationTime = 3.5f;
}

settings SlopeSlidingTurnSettings for USplineSlopeSlidingTurnSettings
{
	SlopeSlidingTurnSettings.MaxSideSpeed = 2500.f;
	SlopeSlidingTurnSettings.DefaultSideAccelerationTime = 3.5f;
	SlopeSlidingTurnSettings.SteeringTowardsOppositeSideAccelerationTime = 2.5f;
}

struct FSplineSlopeSlidingSettings
{
	//--------------- RubberBandSettings --------------------------//

	// If May is this far behind cody then she will get a negative speed boost.
	const float MayStartClampingSpeedDistance = 750.f;

	// If May is this far ahead or more then cody then she will get max negative speed boost.
	const float MayMaxForwardDistanceToCody = 500.f;

	// At this distance may will start to get a speed boost to catch up to cody.
	const float MayStartCatchingUpDistance = 1500.f;

	// If May is this far or more behind cody then she will gain max speed boost.
	const float MayMaxBehindDistanceToCody = 2000.f;

	// How much May will slow down while infront of cody.
	const float RubberBandBreakSpeed = 1500.f;

	// How much faster may will become while cody is to far ahead.
	const float RubberBandSpeedBoost = 500.f;

	//--------------- SplineSideVelocity --------------------------//

	// The max incline value we will care about, higher values won't further affect the speed.
	const float SideInclineMaxDot = 0.55f;

	// The Side incline has to be higher than this value to begin having a affect.
	const float SideInclineActivationTreshold = 0.10f;

	// How much of an effect the incline can have on the end speed.
	const float InclineEffectModifier = 0.f;

	// At this distance from the spline we will start removing speed from your turn.
	const float StartClampingSideSpeedDistance = 2000.f;

	// At this distance we force the player back in towards the spline.
	const float MaxDistanceAllowedFromSpline = 2200.f;

	//-------------- Jumping ----------------------------------------//
	const float JumpImpulse = 1750.f;

	const float SecondJumpImpulse = 1250.f;
}

struct FSplineSlopeCameraSettings
{
	// how long we wait for no input delay before the chase camera activates.
	const float CameraInputDelay = 0.75f;
	const float MovementInputDelay = 0.1f;

	// How long it takes for the camera to get the target rotation.
	const float AccelerationDuration = 3.0f;

	// How much further forward to look on the track the focus point should be.
	const float FutureDistanceToLookAt = 7500.f;

	// Offset to pitch the camera away from the track.
	const float TargetPitchOffset = 10.f;
}
