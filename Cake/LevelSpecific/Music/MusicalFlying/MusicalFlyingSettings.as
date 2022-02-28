
UCLASS(meta=(ComposeSettingsOnto = "UMusicalFlyingSettings"))
class UMusicalFlyingSettings : UHazeComposableSettings
{
	// Time since starting flying (except from going from hover) that it can't be canceled.
	UPROPERTY(Category = "Flying|Deprecated")
	float PreventCancelTime = 1.1f;

	// How fast we fly.
	UPROPERTY(Category = Flying, meta = (DisplayName = "Acceleration"))
	float FlyingSpeed = 2650.0f;

	UPROPERTY(Category = Flying)
	float FlyingSpeedMax = 5000.0f;

	UPROPERTY(Category = Flying, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float FlyingDrag = 0.6f;

	UPROPERTY(Category = Flying, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float NoInputDrag = 0.4f;

	UPROPERTY(Category = Flying, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float ImpulseDrag = 0.1f;

	UPROPERTY(Category = Flying)
	float VerticalAcceleration = 5000.0f;

	UPROPERTY(Category = Flying, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float VerticalDrag = 0.15f;

	// When the current speed is less than this (fraction 0-1), character will start hovering.
	UPROPERTY(Category = "Flying|Deprecated", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float Hovering = 0.3f;

	// How much we break, if this is more than FlyingSpeed you will end up reversing.
	UPROPERTY(Category = "Flying|Deprecated")
	float BreakingThrottle = 1000.0f;

	// turn rate when reaching max speed.
	UPROPERTY(Category = Flying)
	float TurnRateYaw = 30.0f;

	// Time its takes to maximize TurnRateYaw.
	UPROPERTY(Category = "Flying|Deprecated")
	float TurnRateYawLag = 1.0f;

	// How much the character turns up and down.
	UPROPERTY(Category = Flying)
	float TurnRatePitch = 20.0f;

	UPROPERTY(Category = Flying)
	float VerticalPitchInput = 150.0f;

	UPROPERTY(Category = Flying)
	float VerticalPitchInputDrag = 0.125f;

	UPROPERTY(Category = Flying)
	float LoopPitchSpeed = 450.0f;

	UPROPERTY(Category = Camera)
	float CrosshairHorizontalMovementModifier = 1.0f;

	UPROPERTY(Category = Camera)
	float CrosshairVerticalMovementModifier = 1.0f;

	UPROPERTY(Category = Camera)
	float CrosshairInterpSpeed = 3.0f;

	// Time its takes to maximize TurnRatePitch.
	UPROPERTY(Category = "Flying|Deprecated")
	float TurnRatePitchLag = 1.0f;

	// How far up in the air the player will be pushed first activating flying.
	UPROPERTY(Category = "Flying|Startup")
	float StartupImpulse = 1000.0f;

	UPROPERTY(Category = "Flying|Startup", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float StartupImpulseDrag = 0.5f;

	// The speed the player can be controlled with while starting up the jetpack.
	UPROPERTY(Category = "Flying|Deprecated")
	float StartupMovementSpeed = 1500.0f;

	// The lower the value the more sluggish turning on pitch axis will be when diving or flying straigh upwards.
	UPROPERTY(Category = "Flying|Deprecated", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float PitchBankingScalar = 0.1f;

	// Modify pitch banking exponentially to make it less linear.
	UPROPERTY(Category = "Flying|Deprecated", meta = (ClampMin = 1.0))
	float PitchBankingCurve = 1.0f;

	// Forward impulse added when flying enter animation has played.
	UPROPERTY(Category = "Flying|Deprecated")
	float IntialBoost = 2200.0f;

	UPROPERTY(Category = "Flying|Boost")
	float BoostImpulse = 5000.0f;

	UPROPERTY(Category = "Flying|Boost", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float BoostDrag = 0.9f;

	// This cooldown is only for player input.
	UPROPERTY(Category = "Flying|Boost")
	float BoostCooldown = 1.0f;

	// Wait a while before starting to fly. Also used when falling.
	UPROPERTY(Category = "Flying|Deprecated")
	float StartDelay = 0.6f;
	UPROPERTY(Category = "Flying|Deprecated")
	float StartDelayFromHover = 0.5f;

	// Modifies velocity when flying up or down. So you go faster downward and slower upward. The higher value is, the greater the effect becomes.
	UPROPERTY(Category = "Flying|Deprecated", meta = (ClampMin = "-1.0", ClampMax = "1.0"))
	float HeightScalar = 0.0f;
	// Scales the pitch to allow high turning rate but with less responsivness while flying horizontally.
	UPROPERTY(Category = "Flying|Deprecated", meta = (ClampMin = "0.0", ClampMax = "0.98"))
	float PitchTurnScalar = 0.58f;

	UPROPERTY(Category = "Flying|Deprecated")
	UCurveFloat StartupAccelerationGround;
	UPROPERTY(Category = "Flying|Deprecated")
	UCurveFloat StartupAccelerationInAir;

	// Define the snappiness of the Camera turn when turning.
	UPROPERTY(Category = "Flying|Deprecated")
	float CameraTurnLagInput = 2.5f;
	// Define the snappiness of the Camera turn when no longer pressing any direction on the stick.
	UPROPERTY(Category = "Flying|Deprecated")
	float CameraTurnLagNoInput = 1.1f;
	// This works as a scalar for LookAtPointYaw/PitchOffset.
	UPROPERTY(Category = "Flying|Deprecated")
	float LookAtPointForwardProjection = 3000.0f;
	// How much extra the camera will turn on the yaw pitch.
	UPROPERTY(Category = "Flying|Deprecated")
	float LookAtPointPitchOffset = 30.0f;
	// How much extra the camera will turn on the pitch pitch.
	UPROPERTY(Category = "Flying|Deprecated")
	float LookAtPointYawOffset = 90.0f;

	// Time it takes to reach full input from the stick.
	UPROPERTY(Category = "Flying|Deprecated")
	float CameraInputLag = 1.5f;

	UPROPERTY(Category = "Flying|Deprecated")
	float HoverAcceleration = 3700.0f;
	
	UPROPERTY(Category = "Flying|Deprecated")
	float HoverDrag = 3.5f;

	UPROPERTY(Category = Camera)
	float HorizontalCameraOffset = 300.0f;
}
