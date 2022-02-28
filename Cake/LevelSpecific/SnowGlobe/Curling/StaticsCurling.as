enum ECurlingPlayerTurn
{
	May,
	Cody
};

enum ECurlingGameState
{
	Inactive,
	Active,
	ShootInPlay,
	Complete
};

enum EObstacleRound
{
	RoundOne,
	RoundTwo,
	RoundThree
};

enum ECurlingPlayerTarget
{
	May,
	Cody
};

struct FCurlingSkateSettings
{
	const float Acceleration = 750.f;
	const float Friction = 0.75f;
	const float MaxSlope = 30.f;

	const float RotationRate = 50.f;
	const float RotationRateAccelerationDuration = 1.4f;
	const float RemoteAcceleratedRotationDuration = 0.8f;
}

namespace CurlingTags
{
	const FName StoneMay = n"StoneMay";
	const FName StoneCody = n"StoneCody";
}