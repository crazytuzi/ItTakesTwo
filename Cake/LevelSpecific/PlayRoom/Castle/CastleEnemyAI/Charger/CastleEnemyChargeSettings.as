namespace ChargerSettings
{
	// Telegraph
    const float ChargeTelegraphTime = 2.8f;
	
	// Movement
    const float ChargeSpeed = 2000.f;

	const float ChargeSpeedInitial = 800.f;

	const float ChargeAcceleration = 1800.f;
	
    const float ChargeDurationMax = 10.f;	
	
	// Stun
	const float ChargeStunTime = 4.f;

	const float ChargeStunBounceDistance = 300.f;

	const float ChargeStunInterpSpeed = 18.f;

	// Post stun turn
	// If the angle difference between the target is less than this, it won't trigger a turn
	const float PostStunTurnMinimumAngle = 25.f;

	const float PostStunTurnDuration = 0.967f;

	const float PostStunTurnStationaryDuration = 0.35f;

	const float PostStunTurnRotationFinishedDuration = 0.767f;


	const float RockfallTelegraphTime = 2.0f;
}