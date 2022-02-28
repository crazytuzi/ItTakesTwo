import Vino.Camera.Components.FocusTrackerComponent;
import Vino.Camera.Components.CameraFollowViewComponent;
import Vino.Camera.Components.CameraSpringArmComponent;



class AFoliageCameraVolume : AHazeCameraVolume
{
	default BrushComponent.AddTag(ComponentTags::AlwaysBlockCamera);
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
	default CameraSettings.Priority = EHazeCameraPriority::Script;
	default CameraSettings.Blend.BlendTime = 2.f;

	UPROPERTY()
	FHazeCameraClampSettings Clamps;
	default Clamps.bUseClampPitchDown = true;
	default Clamps.bUseClampPitchUp = true;
	default Clamps.ClampPitchUp = 60.f;
	default Clamps.ClampPitchDown = 60.f;

	UPROPERTY()
	FHazeCameraSpringArmSettings SpringArmSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnVolumeActivated.AddUFunction(this, n"VolumeActivated");
		OnVolumeDeactivated.AddUFunction(this, n"VolumeDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		OnVolumeActivated.Unbind(this, n"VolumeActivated");
		OnVolumeDeactivated.Unbind(this, n"VolumeDeactivated");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UHazeCameraComponent DefaultCamera = UHazeCameraComponent::Get(Player);
			DefaultCamera.CameraCollisionParams.AdditionalIgnoreActors.Remove(this);
			Player.DeactivateCameraByInstigator(this);
			Player.ClearCameraSettingsByInstigator(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void VolumeActivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player == nullptr)
			return;
		
		// Make sure default camera ignores collision with us until fully blended out
		UHazeCameraComponent DefaultCamera = UHazeCameraComponent::Get(Player);
		DefaultCamera.CameraCollisionParams.AdditionalIgnoreActors.AddUnique(this);
		System::ClearTimer(this, GetEnableCollisionDelegateName(Player));

		// Clamp camera so we won't spin around if player goes under camera
		Player.ApplyCameraClampSettings(Clamps, CameraSettings.Blend, this, CameraSettings.Priority);
		Player.ApplyCameraSpringArmSettings(SpringArmSettings, CameraSettings.Blend, this, CameraSettings.Priority);
	}

	UFUNCTION(NotBlueprintCallable)
	void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player == nullptr)
			return;

		Player.ClearCameraSettingsByInstigator(this);

		// Enable collision for player camera after blend out time
		float BlendOutTime = ((CameraSettings.BlendOutTimeOverride < 0.f) ? 2.f : CameraSettings.BlendOutTimeOverride);
		System::SetTimer(this, GetEnableCollisionDelegateName(Player), BlendOutTime, false);
	}

	FName GetEnableCollisionDelegateName(AHazePlayerCharacter Player)
	{
		return (Player.IsMay() ? n"EnableCollisionMay" : n"EnableCollisionCody");		
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableCollisionMay()
	{
		EnableCollision(Game::May);
	}	

	UFUNCTION(NotBlueprintCallable)
	void EnableCollisionCody()
	{
		EnableCollision(Game::Cody);
	}	

	void EnableCollision(AHazePlayerCharacter Player)
	{
		UHazeCameraComponent DefaultCamera = UHazeCameraComponent::Get(Player);
		DefaultCamera.CameraCollisionParams.AdditionalIgnoreActors.Remove(this);
	}
}
