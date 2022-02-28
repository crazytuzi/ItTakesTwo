namespace PlungerGun
{
	const float GameDuration = 60.f;

	const int ProjectilePoolSize = 20;
	const float ProjectileGravity = 2500.f;
	const float ProjectileSpeedMin = 3100.f;
	const float ProjectileSpeedMax = 5800.f;
	const float ProjectileLifetime = 15.f;

	const float ShootCooldown = 0.35f;

	const float MaxChargeTime = 0.8f;
	const float AimSpeed = 90.f;
	const float AimYawClamp = 60.f;
	const float AimPitchClamp = 60.f;

	const float TargetSpeed_Min = 400.f;
	const float TargetSpeed_Max = 800.f;
	const int TargetSpeedIncreaseHitCount = 10;
	const float TargetEdgeResetDelay = 1.2f;
	const float TargetResetSpeed = 1000.f;
	const float TargetBlinkFrequency = 3.f;
	const float TargetWarningTime = 2.f;
	const float TargetMaxSpeed = 1000.f;
	const float TargetRubberBandFactor = 1.4f;

	const float TargetDistanceWarning = 1000.f;
	const float TargetDistanceWarning_MinFreq = 2.f;
	const float TargetDistanceWarning_MaxFreq = 5.f;
}