namespace SwimmingSettings
{
	const FSwimmingSpeedSettings Speed;
	const FSwimmingDashSettings Dash;

	const FSwimmingBreachSettings Breach;
	const FSwimmingSurfaceSettings Surface;
	const FSwimmingStreamSettings Stream;
}
struct FSwimmingSpeedSettings
{	
	// The minimum desired speed the player can have
	UPROPERTY()
	const float DesiredMin = 1300.f;	
	// The desired speed where the player is considered going fast
	UPROPERTY()
	const float DesiredFast = 1750.f;
	// The speed where the player is considered cruising (only obtainable by buoys)
	UPROPERTY()
	const float DesiredCruise = 2200.f;
	// The absolute maximum desired the player can have
	UPROPERTY()
	const float DesiredMax = 2650.f;

	const float InterpSpeedTowardsDesired = 1.4f;
	const float VerticalInputScale = 1.5f;
	const float DesiredDecayDelayAfterDash = 3.f;
	const float DesiredLockDurationAfterBuoy = 2.f;
	const float DesiredDecaySpeed = 100.f;
	const float DesiredDecaySpeedAtZeroInput = 1000.f;
}

struct FSwimmingDashSettings
{
	const float DesiredSpeedIncrease = 500.f;
	const float ExtraBoostSpeed = 500.f;
	const float Cooldown = 1.8f;
}

struct FSwimmingStreamSettings
{
	UPROPERTY(Category = "Stream")
	float StreamPlayerVerticalAcceleration = 4000.f;

	UPROPERTY(Category = "Stream")
	float StreamPlayerHorizontalAcceleration = 4000.f;

	UPROPERTY(Category = "Stream")
	float StreamPlayerDrag = 2.f;

	UPROPERTY(Category = "Stream")
	float StreamForwardDrag = 2.f;

	UPROPERTY(Category = "Stream")
	float StreamCameraPredictionDistance = 500.f;

	UPROPERTY(Category = "Stream")
	float StreamCameraAccelereationSpeed = 2.f;
}

struct FSwimmingBreachSettings
{
	// The speed the player has to be, or exceed, for breach to activate
	const float RequiredSpeedForBreach = 1650.f;

	// The minimum initial speed the player will have when breach triggers
	const float MinimumSpeed = 2400.f; //1800.f;
	
	// The maximum initial speed the player will have when breach triggers
	const float MaximumSpeed = 3500.f; //3000.f;

	const float Gravity = 3000.f;

	// How fast the horizontal velocity will be rotated towards target direction
	const float TurnRateDegrees = 80.f;
	// The lowest amount of rotation rate you can have based on input
	const float MinimumTurnRateScale = 0.5f;
}

struct FSwimmingSurfaceSettings
{
	// If you are going at or above this speed, you will be going to fast for vacuum to kick in
	const float VacuumTotalSpeedThreshold = 3000.f;
	
	// If the players speed is higher than this threshold, they will not be affected by vacuum
	const float VacuumDownwardsSpeedThreshold = 400.f;


	// If inside this range, the player will be vacuumed into surface
	const float VacuumRange = 600.f;

	// Acceleration scaled by distance to surface (very close is almost 100% of acceleration)
	const float VacuumAcceleration = 600.f;

	// Acceptance range when falling from above
	const float AcceptanceRangeAboveSurface = 100.f;

	// Acceptance range when swimming up from below
	const float AcceptanceRangeBelowSurface = 160.f;

	// Velocity drag while in surface moves
	const float Drag = 1.3f;

	// Horizontal acceleration scaled by input
	const float HorizontalAcceleration = 1200.f;


	// The total duration of the dive, from button input
	const float DiveDuration = 0.6f;

	// Downwards acceleration during the dive
	const float DiveAcceleration = 3000.f;

	// How long before the acceleration will kick in after pressing input
	const float DiveDelay = 0.3f;

	const float JumpImpulse = 1400.f;
}
