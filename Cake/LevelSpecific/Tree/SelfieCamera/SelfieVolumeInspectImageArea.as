class ASelfieVolumeInspectImageArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(Category = "Cam Settings")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.75f;
			Player.ApplyCameraSettings(SpringArmSettings, Blend, this);
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.ClearCameraSettingsByInstigator(this, 1.75f);
			// Player.ClearSpecificCameraSettings(SpringArmSettings.CameraSettings, SpringArmSettings.ClampSettings, SpringArmSettings.SpringArmSettings, this, 1.2f);
		}
    }
}