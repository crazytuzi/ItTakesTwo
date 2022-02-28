struct FIceSkatingSettings
{
	const float SkateOffsetHeight = 6.f; // 10.f
}

struct FIceSkatingSlowSettings
{
	const float Acceleration = 3500.f;

	// Friction when inputting towards the velocity
	const float Friction_Min = 0.4f;
	// Friction when inputting away from the velocity
	const float Friction_Max = 1.7f;

	const float MaxSlope = 30.f;
}

struct FIceSkatingFastSettings
{
	const float Threshold = 2500.f;
	const float MaxSpeed_Flat = 3000.f;
	const float MaxSpeed_Slope = 3500.f;
	const float MaxSpeed_Hard = 3500.f;

	const float MaxSpeedAcceleration = 0.5f;

	const float MaxSpeedBrake_Min = 0.3f;
	const float MaxSpeedBrake_Max = 2.2f;
	const float MaxSpeedBrake_Hard = 2.4f;

	const float MaxSpeedGainSpeed = 600.f;

	const float TurnSpeed_Min = 80.f;
	const float TurnSpeed_Max = 90.f;

	const float BrakeCoeff = 1.5f;
}

struct FIceSkatingStumbleSettings
{
	const float MinStumbleSpeed = 1500.f;
	const float Friction = 1.5f;

	const float Duration = 0.6f;
	const float TurnEnableTime = 0.4f;
	const float TurnRate = 1.5f;
}

struct FIceSkatingBoostSettings
{
	const float Impulse = 1500.f;
	const float MinImpulse = 0.f;

	const float AirMinSpeed = 1200.f;
	const float AirForwardImpulse = 1800.f;
	const float AirUpImpulse = 400.f;
	const float AirBoostDuration = 0.5f;
	const float AirBoostGravityScale = 0.2f;
	const float AirBoostGravityFadeStartTime = 0.2f;
	const float AirBoostFriction = 3.5f;

	const int NumCharges = 3;
	const float ChargeTime = 1.f;
}

struct FIceSkatingSlopeSettings
{
	const float Gravity = 1500.f;
	const float UphillMultiplier = 0.5f;

	const float TurnSpeed = 0.8f;

	const float MinTurnAngle = 10.f;
	const float MaxTurnAngle = 40.f;

	const float SlopeMaxSpeed = 6000.f;

	const float MaxSlopeAngle = 89.f;
}

struct FIceSkatingAirSettings
{
	const float Gravity = 4800.f;

	const float TurnSpeed = 80.f;
	const float BrakeCoeff = 1.6f;

	const float EscapeSpeed = 500.f;
	const float MaxFallSpeed = 5800.f;

	const float GlideSearchRadius = 200.f;
	const float GlideSearchUpOffset = 1000.f;
	const float GlideSearchHeight_Grounded = 2500.f;
	const float GlideSearchHeight_Airborne = 2500.f;
}

struct FIceSkatingJumpSettings
{
	const float GroundImpulse = 1500.f;
	const float AirImpulse = 1500.f;
	const float AirVelocityRemoval = 0.8f;

	const float GracePeriod = 0.25f;
	const float JumpCooldownPeriod = 0.3f;
}

struct FIceSkatingCameraSettings
{
	const float ChaseSpeedMin = 1000.f;
	const float ChaseSpeedMax = 2400.f;

	const float InputPauseDuration = 1.2f;
	const float ChaseDuration = 2.f;
	const float VerticalChaseSpeed = 1.2f;

	const float BaseExtraPitch = 4.f;
	const float ChaseSpeed = 8.f;
	const float ChaseSpeedAccelerateDuration = 2.2f;
	const float TurnOffsetAmount = 230.f;

	const float UphillZoomDistance = 200.f;
	const float UphillZoomPivotOffset = 150.f;
	const float UphillZoomAccelerateDuration = 4.f;

	const float SpeedZoomAccelerateDuration = 9.f;
}

struct FIceSkatingTuckSettings
{
	const float HoldDelay = 0.4f;
	const float TurnSpeed = 40.f;
	const float MaxSpeed = 8000.f;
	const float MaxSpeedBrake = 1.2f;
}

struct FIceSkatingSkidSettings
{
	const float TurnSpeed = 150.f;
	const float BrakeCoeff = 0.07f;
}

struct FIceSkatingGrindSettings
{
	const float GrappleExtraHeight = 300.f;
	const float GrappleGravity = 9200.f;
	const float JumpUpImpulse = 2000.f;
	const float JumpSideImpulse = 600.f;

	const float LaunchDuration = 0.5f;
}

struct FIceSkatingMagnetSettings
{
	const float GateLockDistance = 3000.f;
	const float BaseForceFeedback = 0.1f;
	const float DistanceForceFeedback = 0.4f;
	const float GateLaunchDuration = 0.9f;
	const float GateLaunchFov = 20.f;
	const float GateLaunchZoom = 500.f;

	const float GateAirFriction = 3.2f;
	const float GateAirGravity = 9000.f;
}

struct FIceSkatingHardBrakeSettings
{
	const float MinSpeed = 1700.f;
	const float Angle = 45.f;

	const float Force = 1800.f;
	const float Friction = 2.0f;

	const float Impulse = 1400.f;
}

struct FIceSkatingSolverSettings
{
	const float SurfaceMaxEscapeSpeed = 800.f;
}

struct FIceSkatingInputSettings
{
	const float InputPauseGraceDuration = 0.2f;
}

struct FIceSkatingGroundFindSettings
{
	const float SearchHeight = 4000.f;
}

struct FIceSkatingImpactSettings
{
	const float SoftThreshold = 1700.f;
	const float SoftImpulse = 400.f;

	const float HardThreshold = 2900.f;
	const float HardImpulseDrag = 2.2f;
	const float HardUpImpulse = 1500.f;
	const float HardSpeedLoss = 0.6f;
	const float HardDuration = 0.2f;

	const float Cooldown = 1.8f;
}