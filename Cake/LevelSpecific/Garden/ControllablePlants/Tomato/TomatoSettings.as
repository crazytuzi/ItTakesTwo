
UCLASS(meta=(ComposeSettingsOnto = "UTomatoSettings"))
class UTomatoSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Physics)
	float Acceleration = 2500.0f;
	UPROPERTY(Category = Physics, NotEditable)
	float InAirAcceleration = 500.0f;
	UPROPERTY(Category = Physics)
	float MaxSpeed = 9000.0f;
	// The lower the value, the faster we stop.
	UPROPERTY(Category = Physics, meta = (ClampMin = 0.0, ClampMax = 1.0)) 
	float Friction = 0.9f;
	UPROPERTY(Category = Physics, NotEditable)
	float SlopeFriction = 1.65f;
	UPROPERTY(Category = Physics, NotEditable)
	float SlopeSpeed = 200.0f;
	UPROPERTY(Category = Physics, NotEditable)
	float JumpHeight = 950.0f;
	UPROPERTY(Category = Physics)
	float DashImpulse = 5000.0f;

	// Increase friction exponentially when above this value.
	UPROPERTY(Category = "Physics|Advanced")
	float SpeedFrictionModifier = 5000.0f;

	// How much of the current velocity that will be used as impulse when hitting a wall or enemy. This is in percent.
	UPROPERTY(Category = Physics)
	float Bounce = 0.5f;
	// This is only visual, how fast the tomato will rotate in relation to it's velocity.
	UPROPERTY(Category = Rotation)
	float RotationSpeed = 0.55f;
	// DashCapability must deactivate before a new dash can be triggered.
	UPROPERTY(Category = Dash)
	bool bMustDeactivateCapability = true;
	UPROPERTY(Category = Dash)
	float DashCooldown = 0.4f;
	UPROPERTY(Category = Dash)
	float DashTargetRange = 2000.0f;
	UPROPERTY(Category = Dash)
	float DashTargetAngle = 50.0f;
	// Will exit dash when velocity is less than this value.
	UPROPERTY(Category = Dash)
	bool bExitDashBasedOnVelocity = true;
	UPROPERTY(Category = Dash)
	float ExitDashVelocity = 500.0f;
	// Exit dash when the dash has moved this length or more.
	UPROPERTY(Category = Dash)
	bool bExitDashBasedOnLength = false;
	UPROPERTY(Category = Dash)
	float ExitDashLength = 1000.0f;
	UPROPERTY(Category = Dash)
	float HitRadius = 150.0f;
	
	// Disable dash damage temporary when entering goo.
	UPROPERTY(Category = Goo)
	float DashDisableTime = 0.5f;
}
