struct FSwimmingVortexSettings
{
	// How fast the vortex will pull you into the center
	const float VortexStiffness = 9.f;
	const float VortexDamping = 0.7f;

	// The strength of the drag on the players velocity when the enter the vortex
	const float VerticalDrag = 5.f;

	// The strength of the Upwards and Downwards accel
	const float VerticalAcceleration = 5000.f;

	// How fast you will rotate in degrees per second
	const float RotationRate = 100.f;

	// The deadzone size from the characters forward vector in degrees
	// Checks from either side of forward, so 10 degrees is a 20 degree range
	//float ForwardDeadzone = 15.f;

	// The pitch value of the chase camera (pitched up from the forward vector of the character)
	const float ChaseCameraPitch = 0.f;

	// The acceleration of the chase camera
	const float ChaseCameraAcceleration = 0.75f;

	// ------------ [DASH] -----------

	// The distance that the player will move backwards during the anticipation period
	const float DashAnticipationDistanceFromCenter = 250.f;

	// the duration of the anticipation before the dash triggers
	const float DashAnticipationTime = 0.4f;

	// The minimum duration of the dash (in water)
	const float DashDuration = 0.7f;

	// The initial impulse strength of the dash
	const float DashImpulse = 9000.f;

	// The direction of the dash, transformed onto the player
	const FVector DashDirection = FVector(1.f, 0.f, 0.1f).GetSafeNormal();

	// The amount of drag on the horizontal velocity
	const float DashDragStrength = 1.f;

	// The duration of the gravity lerp
	const float DashGravityLerpTimer = 1.f;

	// The maximum strength of gravity during the dash
	const float DashGravityStrength = 3200.f;

	// The horizontal turn rate of the dash
	const float DashTurnRate = 60.f;

	// How much pitch the camera will follow when in the dash (0 will ignore pitch entirely)
	const float DashCameraPitchScale = 0.6f;

	// How long (in seconds) it takes for the camera to reach the moving target location
	const float DashCameraAcceleration = 0.8f;
}