UCLASS(Meta = (ComposeSettingsOnto = "UWallWalkingAnimalRiderSettings"))
class UWallWalkingAnimalRiderSettings : UHazeComposableSettings
{
	UPROPERTY()
	float WallCameraSlerpSpeed = 5.f;

	UPROPERTY()
	float FloorCameraSlerpSpeed = 1.f;

	UPROPERTY()
	float TransitionCameraSlerpSpeed = 0.1f;
}
