USTRUCT()
struct FBoatsledJumpCameraSettings
{
	UPROPERTY()
	float FovValue = 110.f;

	UPROPERTY()
	FHazePointOfInterest PointOfInterest;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY()
	float CameraShakeScale;
}