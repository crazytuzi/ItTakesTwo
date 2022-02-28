
UCLASS(meta=(ComposeSettingsOnto = "UDandelionSettings"))
class UDandelionSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float FallSpeedAcceleration = 35.0f;

	UPROPERTY(Category = Movement)
	float FallSpeedMaximum = 35.0f;

	UPROPERTY(Category = Movement)
	float HorizontalAcceleration = 5000.0f;

	UPROPERTY(Category = Movement, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float HorizontalDrag = 0.9f;

	UPROPERTY(Category = Movement)
	float HorizontalVelocityMaximum = 1000.0f;
}
