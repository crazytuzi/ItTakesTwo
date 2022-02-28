struct FCraneRotationSettings
{
	UPROPERTY(BlueprintReadOnly)
	float RotationRate = 25.f;

	UPROPERTY(BlueprintReadOnly)
	float AccelerationDuration = 1.f;
}

struct FCraneConstraintSettings
{
	UPROPERTY(BlueprintReadOnly)
	float MinimumLength = 800.f;

	UPROPERTY(BlueprintReadOnly)
	float MaximumLength = 1750.f;

	UPROPERTY(BlueprintReadOnly)
	float LengthAdjustRate = 250.f;

	UPROPERTY(BlueprintReadOnly)
	float AccelerationDuration = 1.f;
}

struct FCraneAlignSettings
{
	// Angle in degrees the align will kick in
	UPROPERTY(BlueprintReadOnly)
	float AcceptanceAngle = 8.f;

	// The rate in which the target will interp to 0, in angles per second
	UPROPERTY(BlueprintReadOnly)
	float RotationInterpSpeed = 2.5f;

	UPROPERTY(BlueprintReadOnly)
	float HeightInterpSpeed = 100.f;

}