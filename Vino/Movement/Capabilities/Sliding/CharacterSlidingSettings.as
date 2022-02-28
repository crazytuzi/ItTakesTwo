UCLASS(Meta = (ComposeSettingsOnto = "USlidingSettings"))
class USlidingSettings : UHazeComposableSettings
{
	// The total height of the capsule when in crouch or slide
	UPROPERTY(Category = "General")
	float CrouchHeight = 110.f;
	
	// The minimum slope angle required to go into sliding after a ground pound
	UPROPERTY(Category = "General")
	float GroundPoundSlopeMinimumAngle = 17.5f;

	UPROPERTY(Category = "General")
	float GroundPoundMinimumSpeed = 1750.f;

	UPROPERTY(Meta = (ComposedStruct, ShowOnlyInnerProperties))
	FSlidingSpeedSettings SpeedSettings;

	UPROPERTY(Meta = (ComposedStruct, ShowOnlyInnerProperties))
	FSlidingTurningSettings TurningSettings;
}

USTRUCT(Meta = (ComposedStruct))
struct FSlidingSpeedSettings
{
	UPROPERTY()
	float Acceleration = 3200.f;

	UPROPERTY()
	float Decceleration = 1200.f;

	// The speed that sliding will accelerate towards if you are too high
	UPROPERTY()
	float SoftMaximumSpeed = 2600.f;

	// THe absolute maximum speed, that sliding will never exceed
	UPROPERTY()
	float MaximumSpeed = 4000.f;

	// THe absolute maximum speed, that sliding will never exceed
	UPROPERTY()
	float PostIdealMaximumSpeedDrag = 1.6f;
}

USTRUCT(Meta = (ComposedStruct))
struct FSlidingTurningSettings
{
	// The rate of rotation from player input
	UPROPERTY()
	float InputRotationRate = 80.f;

	// The rate of rotation from slope angle, where the character will turn into a slope slightly based on this rate
	UPROPERTY()
	float SlopeRotationRate = 80.f;
}