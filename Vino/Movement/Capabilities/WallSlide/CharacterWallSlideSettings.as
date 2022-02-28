
struct FCharacterWallSlideSettings
{
	// Input has to be longer then this to be read for direction vs wall check.
	float InputMinSizeSquared = FMath::Pow(0.5f, 2.f);

	// How far to trace when doing center of capsule trace.
	float CenterDistanceCheck = 16.f;

	// If the hit surface has a bigger angle in degrees from the characters worldup then the wallslide will be rejected.
	float MaxWallslideAngle = 6.f;	

	// How fast the character rotatates to lineup with the wall, in radians per second.
	float RotationTime = 13.f;

	// How long after cancelling out of a wallslide before we can enter a new wallslide
	float CancelDisableDuration = 0.4f;

	// Minimum time before you can wallslide again after doing a wallslidejumpup.
	float JumpUpDisableDuration = 0.65f;

	// If you repeatedly verticaly walljump this amount of time will be added to the disable time.
	float JumpUpDisableBonusDuration = 0.25f;

	// How much time has to pass before we reset the count on vertical walljumps.
	float JumpUpCounterResetTime = 0.45f;

	// Minimum time before you can wallslide again after doing a WallSlideJumpAway.
	float JumpAwayDisableDuration = 0.82f;	

	// How many repeated vertical wall jumps you can do before we add more disable time.
	int NormalMaxVerticalJumps = 2;

	// Bonus height you get on you wallslide check after you have used a AirJump.
	float WallslideReactivationBonusHeight = 180.f;
}

struct FCharacterWallSlideHorizontalSettings
{
    float StickInputDelayTime = .4f;
    float StickInputFadeInTime = 0.5f;

	float SideInputDelayTime = .05f;
    float SideInputDelayFadeInTime = 0.2f;

	// When the player is going down with this speed then horizontaljump will deactivate.
	float HorizontalJumpDeactivationSpeed = 1000.f;
}

UCLASS(meta=(ComposeSettingsOnto = "UWallSlideDynamicSettings"))
class UWallSlideDynamicSettings : UHazeComposableSettings
{
	// If the character is moving verticly upwards with this speed the it will not start leadgegrabbing.
	UPROPERTY()
	float MaxUpwardsSpeedToStart = 250.f;

	// When checking if the wall is solid check for how many vertical traces we do.
	UPROPERTY()
	int NumberOfCenterTracingSegments = 4;

	// How far to trace when doing side traces.
	UPROPERTY()
	float SideDistanceCheck = 64.f;

	// Specifies how much extra we add to the sides of the characters sides when tracing on the sides.
	UPROPERTY()
	float SidesExtraWidth = 12.f;

	// Units per second character slides down the wall.
	UPROPERTY()
	float WallSlideSpeed = 150.f;

	// How fast the character slides while in fast slide mode.
	UPROPERTY()
	float FastWallSlideSpeed = 825.f;

	// How fast the character accelerates to its wanted speed
	UPROPERTY()
	float WallSlideInterpSpeed = 0.75f;

	// How fast the character accelerates to its wanted speed
	UPROPERTY()
	float WallSlideFastInterpSpeed = 2.f;
}
