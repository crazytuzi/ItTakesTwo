class UMagneticPickupDataAsset : UDataAsset
{
	UPROPERTY(Category = "Levitation", DisplayName = "Acceleration Curve")
	UCurveFloat LevitationAccelerationCurve;

	UPROPERTY(Category = "Levitation", DisplayName = "Camera Shake")
	TSubclassOf<UCameraShakeBase> LevitationCameraShakeClass;

	UPROPERTY(Category = "Levitation")
	float LevitationHeight = 400.f;


	UPROPERTY(Category = "Attraction", DisplayName = "Acceleration Curve")
	UCurveFloat AttractionAccelerationCurve;

	UPROPERTY(Category = "Attraction", DisplayName = "Camera Shake")
	TSubclassOf<UCameraShakeBase> AttractionCameraShakeClass;
}