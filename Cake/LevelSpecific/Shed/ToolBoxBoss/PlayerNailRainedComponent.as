import Peanuts.Animation.Features.Shed.LocomotionFeatureToolBossNailed;
class UPlayerNailRainedComponent : UActorComponent
{
	UPROPERTY()
	AHazeActor HitNail;

	UPROPERTY()
	FHitResult GroundHit;

	UPROPERTY()
	float BlendSpaceValue;

	UPROPERTY(BlueprintReadOnly)
	bool bIsAttachedToNail = false;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	ULocomotionFeatureToolBossNailed CodyFeature;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	ULocomotionFeatureToolBossNailed MayFeature;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UStaticMesh AnimatedNailMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedBackEffect;

	void ResetNail()
	{
		HitNail = nullptr;
		GroundHit = FHitResult();
	}
}