
/*
	Specific settings on how the actual movement in and out from a volume can behave. Seperated from MusicalFlyingSettings because
*/

UCLASS(meta=(ComposeSettingsOnto = "UMusicFlyingReturnToVolumeSettings"))
class UMusicFlyingReturnToVolumeSettings : UHazeComposableSettings
{
	// Time in seconds from exiting the volume until the player starts turning back into the volume.
	UPROPERTY(Category = ReturnToVolume, meta = (ClampMin = 0.0))
	float TimeUntilReturning = 1.5f;

	// Max distance teh player will attempt to fly outwards when exiting a flying volume before returning.
	UPROPERTY(Category = ReturnToVolume, meta = (ClampMin = 0.0))
	float FlyOutDistanceMax = 7000.0f;

	// Time in seconds from when the player has re-entered a flying volume and control is yet to be resumed.
	UPROPERTY(Category = ReturnToVolume, meta = (ClampMin = 0.0))
	float ExitDelay = 1.0f;

	// THe player tries to follow this spline point, choose a reasonable speed.
	UPROPERTY(Category = ReturnToVolume, meta = (ClampMin = 0.0))
	float SplinePointMovementSpeed = 4500.0f;
}
