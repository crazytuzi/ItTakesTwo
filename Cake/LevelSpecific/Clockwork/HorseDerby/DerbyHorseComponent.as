
enum EDerbyHorseState
{
	Inactive,
	GameActive,
	AwaitingStart,
	GameWon,
	Travelling
}

enum EDerbyHorseMovementState
{
	Jump,
	Crouch,
	Run,
	Hit,
	Still,
	Trot
}

class UDerbyHorseComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	float MinimumJumpHeight = 200.f;

	float CurrentProgress = 0.f;
	float SpeedMultiplier = 1.f;
	float MaxSpeedMultiplier = 1.5f;

	float SpeedMultiPercentage = MaxSpeedMultiplier / 100.f;

	EDerbyHorseMovementState MovementState = EDerbyHorseMovementState::Still;
}