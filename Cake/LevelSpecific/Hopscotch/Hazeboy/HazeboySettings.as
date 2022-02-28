import Vino.Trajectory.TrajectoryStatics;

namespace Hazeboy
{
	const float MoveSpeed = 900.f;
	//const float TurnSpeed = 120.f;
	const float TurnSpeed = 2.f;

	const float AimSpeed = 90.f;
	const float AimSyncFrequency = 5.f;

	const float MaxHoldTime = 1.8f;
	const float MaxShootDistance = 3000.f;
	const float MinShootDistance = 900.f;
	const float ShootCooldown = 1.f;

	const float ProjectileSpeedMin = 800.f;
	const float ProjectileSpeedMax = 1800.f;
	const float ProjectileHeight = 800.f;
	const float ProjectileGravity = 3000.f;

	const float ExplosionSizeMin = 50.f;
	const float ExplosionSizeMax = 750.f;
	const float ExplosionDuration = 1.8f;
	const float ExplosionExponent = 2.f;
	const float ExplosionFadeDuration = 1.2f;

	const float HurtDuration = 0.8f;
	const float ImmuneDuration = 2.2f;
	//const float ImmuneDuration = 0.f;
	const float BlinkFrequency = 6.f;

	const float RestartDelay = 3.5f;

	const float PickupSpawnTime = 15.f;

	const float HasteDuration = 8.f;
	const float HasteSpeedMultiplier = 1.6f;
	const float HasteChargeSpeedMultiplier = 1.4f;

	const float SuperChargeExplosionMultiplier = 2.f;

	const float RingStartRadius = 10000.f;
	const float RingEndRadius = 600.f;
	const float RingShrinkDelay = 20.f;
	const float RingShrinkDuration = 35.f;
}

FVector CalculateHazeboyProjectileVelocity(FVector Origin, FVector Target)
{
	float HorizontalSpeed = CalculateHazeboyProjectileHorizontalSpeed(Origin, Target);
	return CalculateVelocityForPathWithHorizontalSpeed(Origin, Target, Hazeboy::ProjectileGravity, HorizontalSpeed);
}

float CalculateHazeboyProjectileHorizontalSpeed(FVector Origin, FVector Target)
{
	FVector Delta = (Target - Origin);
	Delta = Delta.ConstrainToPlane(FVector::UpVector);

	float Dist = Delta.Size();
	float DistAlpha = Math::GetPercentageBetweenClamped(Hazeboy::MinShootDistance, Hazeboy::MaxShootDistance, Dist);

	return FMath::Lerp(Hazeboy::ProjectileSpeedMin, Hazeboy::ProjectileSpeedMax, DistAlpha);
}