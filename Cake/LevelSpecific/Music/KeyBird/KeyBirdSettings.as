
UCLASS(meta=(ComposeSettingsOnto = "UKeyBirdSettings"))
class UKeyBirdSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float VelocityMaximum = 3500.0f;

	UPROPERTY(Category = Movement)
	float Acceleration = 1200.0f;

	UPROPERTY(Category = Movement)
	float Drag = 0.85f;

	UPROPERTY(Category = Movement)
	float TurnRate = 0.38f;

	// The spline point itself will not move unless this bird is within this distance.
	UPROPERTY(Category = Spline)
	float SplineMovementAcceptableDistance = 10000.0f;

	// How fast the spline point will move and the bird will attempt to keep up.
	UPROPERTY(Category = Spline)
	float SplinePointMovementSpeed = 1000.0f;

	UPROPERTY(Category = Advanced)
	FVector2D LookAtMovementScale = FVector2D(0.25f, 1.5f);

	UPROPERTY(Category = Advanced)
	FVector2D LookAtRotationScale = FVector2D(0.75f, 5.0f);

	UPROPERTY(Category = Advanced)
	bool bSlowdownDistance = false;

	UPROPERTY(Category = Advanced)
	FVector2D DistanceSlowdownScale = FVector2D(2000.0f, 100.0f);

	UPROPERTY(Category = StealKey)
	float StealKeyRadius = 3000.0f;
}
