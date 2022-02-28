
UCLASS(Meta = (ComposeSettingsOnto = "UClockworkBirdFlyingSettings"))
class UClockworkBirdFlyingSettings : UHazeComposableSettings
{

	// Acceleration for bird rotation
	UPROPERTY()
	float RotationAccelerationDuration = 2.5f;

	// Acceleration for bird rotation roll
	UPROPERTY()
	float RollAccelerationDuration = 2.f;

	// Amount to roll the bird when yawing
	UPROPERTY()
	float RollDegreesWhenRotating = 65.f;

	// Speed that the bird normally flies at
	UPROPERTY()
	float FlyingSpeed = 6500.f;

	// Acceleration at which the flying speed increases when stick input is given
	UPROPERTY()
	float FlyingSpeedAcceleration = 9000.f;

	// Flying speed threshold for being considered 'high speed'
	UPROPERTY()
	float HighSpeedThreshold = 20000.f;

	// Duration that launching into flying takes
	UPROPERTY()
	float LaunchDuration = 1.f;

	// Maximum speed that the bird can achieve while holding a bomb
	UPROPERTY()
	float FlyingSpeed_WithBomb = 4000.f;

	// Time taken for the bird to land at a prespecified point
	UPROPERTY()
	float LandOnPerchDuration = 1.5f;

	// If holding B while less than this distance from the ground, automatically drop out of flying
	UPROPERTY()
	float AutomaticLandDistance = 700.f;

	// Duration that the dash lasts
	UPROPERTY()
	float DashDuration = 2.f;

	// Cooldown for dashing. Starts only after dash is done
	UPROPERTY()
	float DashCooldown = 0.f;

	// Speed boost given by the dash
	UPROPERTY()
	float DashSpeedBoost = 22000.f;

	// If impacting at this speed, stop flying
	UPROPERTY()
	float ImpactMinSpeedStopFlying = 4000.f;

	// If impacting at this speed, kill the bird
	UPROPERTY()
	float ImpactMinSpeedDeath = 6000.f;

	// Choose a position this many seconds ago when respawning the bird
	UPROPERTY()
	int RespawnLocationPreviousSeconds = 5;
}