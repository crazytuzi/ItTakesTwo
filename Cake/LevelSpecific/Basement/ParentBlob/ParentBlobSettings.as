UCLASS(Meta = (ComposeSettingsOnto = "UParentBlobSettings"))
class UParentBlobSettings : UHazeComposableSettings
{
	UPROPERTY()
	float FacingRotationSpeed = 4.f;

	UPROPERTY()
	float MoveSpeed = 400.f;

	UPROPERTY()
	float AirControl = 450.f;
};