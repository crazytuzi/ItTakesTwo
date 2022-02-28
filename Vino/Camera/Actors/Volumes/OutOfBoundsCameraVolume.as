import Vino.Camera.Components.FocusTrackerComponent;
import Vino.Camera.Components.CameraFollowViewComponent;
import Vino.Camera.Components.CameraSpringArmComponent;

// Use this volume to block off areas where camera should not move, 
// such as below a water surface. 
// The volume will always block camera itself and if the player enters 
// the volume it will activate a custom camera which snaps to player
// camera location, slows to a halt and looks at player until player 
// leaves volume.
// If the Camera property is set, that camera will be used instead of 
// the custom camera.
class AOutOfBoundsCameraVolume : AHazeCameraVolume
{
	default BrushComponent.AddTag(ComponentTags::AlwaysBlockCamera);
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
	default CameraSettings.Priority = EHazeCameraPriority::Script;
	default CameraSettings.Blend.BlendTime = 1.f;

	UPROPERTY(DefaultComponent)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraFollowViewComponent ViewFollower;
	default ViewFollower.DontFollowVolume = this; // Camera should never enter volume
	default ViewFollower.DontFollowRange = 0.f;

	UPROPERTY(DefaultComponent, Attach = ViewFollower)
	UFocusTrackerComponent FocusTracker;
	default FocusTracker.RotationSpeed = 0.5f;

	UPROPERTY(DefaultComponent, Attach = FocusTracker)
	UHazeCameraComponent Camera;

	// To avoid camera spinning around if we pass beneath, we might want to clamp yaw around initial rotation
	// If this value >= 180 yaw will not be clamped
	UPROPERTY()
	float ClampYaw = 60.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CameraRoot.SetWorldScale3D(FVector::OneVector);
	}

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

		if (CameraSettings.Camera != nullptr)
		{
			// This camera have been activated instead
			return;
		}

		// Activate our custom camera
		CameraRoot.ActivateCamera(Player, CameraSettings.Blend, this, CameraSettings.Priority);

		if ((ClampYaw >= 0.f) && (ClampYaw < 180.f))
		{
			// Clamp camera so we won't spin around if player goes under camera
			FHazeCameraClampSettings Clamps;
			Clamps.bUseClampYawLeft = true;
			Clamps.bUseClampYawRight = true;
			Clamps.ClampYawLeft = ClampYaw;
			Clamps.ClampYawRight = ClampYaw;
			Clamps.bUseCenterOffset = true;
			FVector UserPlaneCenterDir = Math::ConstrainVectorToPlane(Player.ViewRotation.Vector(), Player.ActorUpVector);
			Clamps.CenterOffset = UserPlaneCenterDir.Rotation();
			Clamps.CenterType = EHazeCameraClampsCenterRotation::WorldSpace;
			Player.ApplyCameraClampSettings(Clamps, CameraSettings.Blend, this, CameraSettings.Priority);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player == nullptr)
			return;

		Player.DeactivateCameraByInstigator(this, CameraSettings.BlendOutTimeOverride);
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
