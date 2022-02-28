

UCLASS(meta=(ComposeSettingsOnto = "URecoilSettings"))
class URecoilSettings : UHazeComposableSettings
{
	// The speed that each bullet will travel at towards its destination.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = Recoil)
	float RecoilSpeed = 120.0f;

	// How much each bullet will travel
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = Recoil)
	float RecoilDistance = 2.5f;

	// How fast the recoil will return to its original position if no input has compensated
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = Recoil)
	float RecoilRecover = 70.0f;

	// TODO: Not yet implemented.
	UPROPERTY(Category = Recoil)
	UCurveFloat RecoilCurve;

	// TODO: Not yet implemented.
	UPROPERTY(Category = Recoil, meta = (ClampMin = 1))
	int BulletsFiredMaximum = 10;

	// TODO: Not yet implemented.
	UPROPERTY(Category = Recoil, meta = (ClampMin = 0.01))
	float TimeBetweenCooldown = 0.5f;

	// When the weapon stops shooting, camera will return to its horizontal origin from when when the first bullet was shot.
	UPROPERTY(Category = Recoil)
	bool bReturnToHorizontalOrigin = false;

	// When the weapon stops shooting, camera will return to its vertical origin from when when the first bullet was shot.
	UPROPERTY(Category = Recoil)
	bool bReturnToVerticalOrigin = true;

	// Limit the random range on the horizontal axis to the right
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits", meta = (ClampMin = -1.0, ClampMax = 0.0))
	float RecoilRangeHorizontalMinimum = -1.0f;

	// Limit the random range on the horizontal axis to the left
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float RecoilRangeHorizontalMaximum = 1.0f;

	// Limit the random range on the vertical axis upwards
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits", meta = (ClampMin = -1.0, ClampMax = 0.0))
	float RecoilRangeVerticalMinimum = 0.0f;

	// Limit the random range on the vertical axis downwards
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits", meta = (ClampMin = 0.0, ClampMax = 1.0))
	float RecoilRangeVerticalMaximum = 1.0f;

	// Limit the total recoil distance from when the weapon started firing on the negative pitch axis. (You probably don't need to touch this value unless the weapon has negative pitch recoil)
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits")
	float PitchMin = -100.0f;

	// Limit how far up the recoil can treverse, starting from when the first shot was fired.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits")
	float PitchMax = 100.0f;

	// From the first bullet, limit how far recoil will kick the camera view, this is usually to the right and should be a negative value.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits")
	float YawMin = -100.0f;

	// From the first bullet, limit how far recoil will kick the camera view, this is usually to the left and should be a positive value.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Recoil|Limits")
	float YawMax = 100.0f;
}
