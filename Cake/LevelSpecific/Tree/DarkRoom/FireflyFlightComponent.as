import Peanuts.Animation.Features.Tree.LocomotionFeatureFireFlies;

class UFireflyFlightComponent : UActorComponent
{
	TArray<AHazeActor> OverlappingSwarms;
	FVector Velocity;
	float AttachedFireflies;
	int TargetAttachedFireflies;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureFireFlies CodyZeroGFeature;
	// ULocomotionFeatureZeroGravity CodyZeroGFeature;
	
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureFireFlies MayZeroGFeature;
	// ULocomotionFeatureZeroGravity MayZeroGFeature;

	UPROPERTY()
	bool bIsLaunching = false;

	UPROPERTY()
	UStaticMesh AttachedFireflyStaticMesh;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraFlightSettings;

	UPROPERTY()
	UMaterial AttachedFireflyMaterial;

	UPROPERTY()
	UNiagaraSystem NiagaraFireflyTrail;

	UPROPERTY()
	bool bStartedFlight = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bStartedFlight)
		{
			bStartedFlight = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnAttachFireflies() {}

	UFUNCTION(BlueprintEvent)
	void OnRemoveAttachedFireflies() {}

	UFUNCTION(BlueprintEvent)
	void OnLaunch(bool bPlayVO) {}
}


