struct FFlyingMachineSettings
{
	// How much the plane will roll when turning
	float MaxRollAngle = 60.f;

	// How fast the roll will lerp towards its target
	float RollLerpCoefficient = 3.f;

	// Degrees/sec to pitch
	float PitchRate = 80.f;

	// Degrees/sec to yaw when turning
	float YawRate = 80.f;

	/* We dont want to be able to pitch over or under 90 degrees, so
	 * when the plane is nearing one of these 'singularities' the
	 * pitch amount will get scaled.
	 */

	// Flat scalar on top of the linear constraint, so that the constraint becomes 0 a little bit before the singularity
	float PitchConstraintScalar = 1.05f;

	// Exponent applied to the constraint, so that it becomes an exponential curve instead of linear
	float PitchConstraintExponent = 5.f;

	/* MOVEMENT */
	float MinSpeed = 3000.f;
	float MaxSpeed = 5500.f;

	// How fast the speed will lerp toward min or max
	float SpeedLerpCoefficient = 1.9f;
	float SpeedBaseDrag = 0.1f;
	float SpeedUpwardsDrag = 3.2f;

	// Exponent to use when creating an exponential curve for how much
	// to lerp the speed based on pitch
	float SpeedPitchExponent = 1.2f;

	float BreakSpeed = 1500.f;
	float BreakLerpCoefficient = 0.8f;

	/* BOOSTING */
	float BoostDuration = 2.f;
	float BoostRegenPause = 0.8f;
	float BoostRegenDuration = 3.4f;
	float BoostSpeed = 6000.f;

	/* SPLINE FOLLOW */
	// Distance to look forward on the spline
	float SplineFollowStepOffset = 3000.f;

	/* COLLISION */
	// Duration of the recoil from collision
	float CollisionRecoilDuration = 2.f;

	// Velocity of the recoil
	float CollisionRecoilVelocity = 3000.f;

	// Minimal angle to recoil away from the collision
	float CollisionRecoilMinAngle = 10.f;

	// Maximum angle to recoil away from the collision
	float CollisionRecoilMaxAngle = 50.f;

	// Dot-product of the impact normal and forward vector needed
	// to trigger a kill of the flying machine
	float CollisionFatalDotAngle = 0.85f;

	/* HEALTH */
	// Max health set when starting the flying machine
	float MaxHealth = 10.f;

	float CollisionMinDamage = 0.2f;
	float CollisionMaxDamage = 5.f;

	float ImpactDamageCooldown = 0.6f;
}

struct FFlyingMachineGliderSettings
{
	// How much the plane will roll when turning
	//default was 40
	float MaxRollAngle = 30.f;

	// How fast the roll will lerp towards its target
	//default was 2
	float RollLerpCoefficient = 1.3f;

	// Degrees/sec to yaw when turning
	//default was 40
	float YawRate = 20.f;

	// Distance to look forward on the spline to predict curvature
	float SplineSearchOffset = 1000.f;

	/* MOVEMENT */
	float PlayerShimmySpeed = 700.f;
	float Speed = 1500.f;

	// Rate at which to lerp the pitch when following a spline position
	float PitchLerpSpeed = 5.f;

	// Maximum speed to be gained from going down-hill
	float MaxEnvironmentalSpeed = 4300.f;

	// Minimum speed lost from going up-hill
	float MinEnvironmentalSpeed = 0.f;

	// How fast speed is gained-lost by going up- and down-hill
	float EnvironmentalLerpSpeed = 0.5f;
}

struct FFlyingMachineGunnerSettings
{
	// Speed of the flak projectiles
	float FlakProjectileSpeed = 100000.f;

	// Frequency (projectiles/second)
	float FlakFireFrequency = 6.f;

	// Time for the camera to transition from flak-cannon-camera to wing-walk-camera (both ways)
	float WingWalkCameraTransitionTime = 1.2f;

	// Speed of the character while walking on the wings
	float WingWalkSpeed = 500.f;

	// How wide of an area in the middle of the wing-walk spline
	// that you can stand to exit wing-walking
	float WingWalkExitSize = 300.f;

	// Pitch clamps for the turret
	float MinPitch = -50.f;
	float MaxPitch = 85.f;

	// Length to trace when looking for a predictive target (while aiming and shooting)
	float TargetTraceLength = 100000.f;
}

/*  Helper struct to express a range between two values
	Used a lot to specify random parameters in the GliderSquirrel */
struct FFloatRange
{
	float Min = 0.f;
	float Max = 0.f;

	FFloatRange(float InMin, float InMax)
	{
		Min = InMin;
		Max = InMax;
	}

	float Lerp(float Value)
	{
		return FMath::Lerp(Min, Max, Math::Saturate(Value));
	}
}

struct FFlyingMachineSquirrelSettings
{
	// Min and max distance behind the plane (lower value means greater distance)
	FFloatRange DistanceLerpRange(0.8f, 1.5f);

	// Offset-length from the plane to chase
	FFloatRange OffsetDistanceRange(800.f, 2000.f);

	// Time to spend chasing behind the plane
	FFloatRange ChaseTimeRange(8.f, 15.f);

	// Time to spend flying towards the plane when attacking
	FFloatRange AttackTimeRange(4.f, 5.f);

	// Minimum mash-rate for mashing squirrels off the wings
	float MashMinRate = 3.f;

	// Mash-scalar for mashing squirrels off the wings (lower value means harder mash)
	float MashScalar = 0.4f;

	// How many times-per-second to fire a projectile
	float FireFrequency = 5.f;

	float ProjectileDamage = 0.3f;
}