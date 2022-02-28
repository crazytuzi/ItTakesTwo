
UCLASS(meta=(ComposeSettingsOnto = "UMurderMicrophoneSettings"))
class UMurderMicrophoneSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float RotationSpeed = 2.0f;

	UPROPERTY(Category = Movement)
	float Acceleration = 500.0f;

	UPROPERTY(Category = Movement)
	float MaxSpeed = 2000.0f;

	UPROPERTY(Category = Movement, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float Damping = 0.8f;

	// Time it takes for hypnosis to activate
	UPROPERTY(Category = Hypnosis, meta = (ClampMin = 0.01))
	float Hypnosis = 0.5f;

	// Wait this time after changing state before being able to change state again.
	UPROPERTY()
	float ChangeStateCooldown = 0.0f;

	UPROPERTY()
	FVector2D SlowdownDistance = FVector2D(20.0f, 600.0f);

	// This value should be larger than the largest value in SlowDownDistance to work best.
	UPROPERTY()
	float AggressiveEatRange = 700.0f;

	// Time until 
	UPROPERTY()
	float TimeUntilEatPlayer = 0.55f;

	UPROPERTY()
	float AvoidanceRadius = 50.0f;

	UPROPERTY(meta = (ClampMin = 0.0))
	float MovementLag = 0.0f;

	UPROPERTY(Category = Wiggle)
	float WiggleSpeed = 0.11f;

	UPROPERTY(Category = Wiggle)
	float WiggleLength = 280.0f;
}
