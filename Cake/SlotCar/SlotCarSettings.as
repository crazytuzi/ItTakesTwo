namespace SlotCarSettings
{
	const FSlotCarSpeedSettings Speed;
	const FSlotCarDeslotSettings Deslot;
	const FSlotCarSlideSettings Slide;
	const FSlotCarRaceSettings Race;
}

struct FSlotCarSpeedSettings
{
	// Constant acceleration scaled by player input
	const float Acceleration = 13000.f;
	// Constant deceleration
	const float Deceleration = 3500.f;
	// A drag exponent applied after deceleration
	const float Drag = 2.0f;
}

struct FSlotCarDeslotSettings
{
	const float RespawnTime = 1.5f;
	const float TurnRateMax = 800.f;
	const float DeslotAngle = 48.f;
	const float DeslotAngleDuration = 0.065f;
}

struct FSlotCarSlideSettings
{
	const float AngleMax = 45.f;
	const float SlideTurnRateStart = 300.f;
	const float SlideTurnRateEnd = 800.f;
}

struct FSlotCarRaceSettings
{
	const float PreLightsTime = 0.7f;
	const float LightsTime = 2.8f;
	const int NumberOfLights = 3;
}