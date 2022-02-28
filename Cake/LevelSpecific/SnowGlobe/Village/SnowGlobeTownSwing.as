import Vino.Camera.Components.CameraSpringArmComponent;

class ASnowGlobeTownSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent ScriptRoot;

	UPROPERTY(DefaultComponent)
	UHazeCameraRootComponent CameraRoot;

   	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraSpringArmComponent SpringArm;

	UPROPERTY(DefaultComponent, Attach = SpringArm)
	UHazeCameraComponent Camera;

	UPROPERTY(Category = Perch)
	USceneComponent Perch;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	TArray<AHazePlayerCharacter> UsingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		CameraRoot.DetachFromParent(true);
		CameraRoot.WorldRotation = FRotator(0.f, Perch.WorldRotation.Yaw, 0.f);
		CameraRoot.WorldLocation = Perch.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update location, but not rotation
		CameraRoot.WorldLocation = Perch.WorldLocation;

		// Safety fix since I've managed to activate both swings at once one time
		for (int i = UsingPlayers.Num() - 1; i >= 0; i--)
		{
			if ((UsingPlayers[i] != nullptr) && (UsingPlayers[i].GetAttachParentActor() != this))
				DeactivateCamera(UsingPlayers[i]);
		}
	}

	UFUNCTION()
	void ActivateCamera(AHazePlayerCharacter Player)
	{
		CameraRoot.WorldLocation = Perch.WorldLocation;
		Player.ApplyCameraSettings(CameraSettings, CameraBlend::Normal(0.5f), this, EHazeCameraPriority::High);
		Player.ActivateCamera(Camera, CameraBlend::Normal(0.5f), this, EHazeCameraPriority::High);
		UsingPlayers.AddUnique(Player);
	}

	UFUNCTION()
	void DeactivateCamera(AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this);	
		Player.ClearCameraSettingsByInstigator(this);	
		UsingPlayers.Remove(Player);
	}
}