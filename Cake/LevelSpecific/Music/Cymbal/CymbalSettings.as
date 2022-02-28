
UCLASS(meta=(ComposeSettingsOnto = "UCymbalSettings"))
class UCymbalSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float MovementSpeed = 2000.0f;

	// Cymbal will return to owner when it has moved this amount of units.
	UPROPERTY(Category = Movement)
	float MovementDistanceMaximum = 2000.0f;
	
	// How fast the cymbal returns to the player. A Low value will make it return slower.
	UPROPERTY(Category = Deprecated, meta = (ClampMin = 0.001, ClampMax = 4))
	float Spring = 0.1f;

	UPROPERTY(Category = Movement, meta = (ClampMin = 0.0, ClampMax = 90.0))
	float MaximumMovementAngle = 25.0f;

	// When seeking a target the Cymbal will ignore the maximum distance it can move and will instead continously accelerate towards its target until hit.
	UPROPERTY(Category = Aiming)
	bool bIgnoreMovementDistanceMaximumWhenSeeking = true;
}
