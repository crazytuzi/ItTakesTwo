event void FOnMagnetHitUpperBound(float ImpactVelocity);
event void FOnMagnetHitLowerBound(float ImpactVelocity);
event void FOnMagnetPassedCenter(float PassVelocity);
event void FOnMagnetWakeUp();
event void FOnMagnetSleep();

enum ESnowGlobeMagnetForceType
{
	// Magnet attraction takes all dimensions into account
	ThreeDimensional,

	// Magnet attraction first get flattened to the rotation axis and normalized, so up and down doesn't matter
	TwoDimensional,

	// Magnet attraction is binary, either -1 or 1, not matter the exact direction. Only forwards or backwards.
	OneDimensional
}

enum ESnowGlobeMagnetRotatingSpringType
{
	Constant,
	Gravity
}
