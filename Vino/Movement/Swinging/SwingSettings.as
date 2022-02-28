struct FSwingSettings
{
	// The constant gravity force throughout the swing. Higher values will increase the rate of the pendulum
	const float GravityForce = 5800.f;

	/* Swing Rotation */
	// How fast the desired direction will rotate towards the target in degrees per second
	const float DesiredDirectionRotationSpeed = 420.f;

	// How fast the velocity will rotate towards the desired directio
	const float VelocityToDesiredRotationSpeed = 2.f;

	// Radius Acceleration
	const float RadiusAccelerationDurationExtend = 3.f;
	const float RadiusAccelerationDurationRetract = 1.f;
}

struct FSwingSpeedSettings
{	
	// The players target speed at the bottom of the swing
	UPROPERTY()
	const float TargetApexSpeed = 2500.f;

	// How fast the speed will be corrected to the target speed;
	UPROPERTY()
	const float SpeedCorrectionForce = 5.f;
}

struct FSwingAttachSettings
{	
	// Attach cooldown when the swing point is in front of the player
	UPROPERTY()
	const float CooldownInFront = 0.25f;

	// Attach cooldown when the swing point is behind the player
	UPROPERTY()
	const float CooldownBehind = 0.5f;
}

struct FSwingDetachSettings
{
	/*
		What percentage of inherited velocity you should include into the jump off (for moving swing points)
		A value of 1 will mean your exit velocity will include all of the inherited velocity, while 0 will ignore it
	*/
	UPROPERTY(meta = (ClampMin = "0", UIMin = "0", ClampMax = "1", UIMax = "1")))
	const float InheritedVelocityScale = 1.f;

	UPROPERTY()
	FSwingJumpOffSettings Jump;

	UPROPERTY()
	FSwingJumpOffSettings Cancel;
}

struct FSwingCameraSettings
{
	UPROPERTY()
	bool bApplySwingCameraSettings = true;

	UPROPERTY()
	bool bUseDetchCamera = true;
}

struct FSwingJumpOffSettings
{
	UPROPERTY()
	float InheritedVelocityScale = 1.f;
	
	UPROPERTY()
	bool bClampSpeed = true;

	UPROPERTY(meta = (ClampMin = "0", UIMin = "0", EditCondition="bClampSpeed", EditConditionHides))))
	float MinSpeed = 1800.f;

	UPROPERTY(meta = (ClampMin = "0", UIMin = "0", EditCondition="bClampSpeed", EditConditionHides))))
	float MaxSpeed = 2200.f;

	UPROPERTY()
	bool bClampAngle = true;

	UPROPERTY(meta = (ClampMin = "-90", UIMin = "-90", ClampMax = "90", UIMax = "90", EditCondition="bClampAngle", EditConditionHides))))
	float MinAngle = -90.f;

	UPROPERTY(meta = (ClampMin = "-90", UIMin = "-90", ClampMax = "90", UIMax = "90", EditCondition="bClampAngle", EditConditionHides))))
	float MaxAngle = 90.f;
}