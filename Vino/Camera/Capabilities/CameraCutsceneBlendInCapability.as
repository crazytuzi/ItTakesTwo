import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// Handle camera while blending in to a cutscene
class UCameraCutsceneBlendInCapability : UHazeCapability
{
	AHazePlayerCharacter PlayerOwner = nullptr;
	UCameraUserComponent User = nullptr;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"CameraCutsceneBlendIn");
    default CapabilityDebugCategory = CameraTags::Camera;

	// After camera update
	default TickGroup = ECapabilityTickGroups::LastDemotable; 

	bool bIsCutsceneActive = false;
	bool bIsCutsceneBlendingIn = false;
	UCameraDetacherComponent CameraDetacher;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);

		// We will only handle this for default camera for now
		CameraDetacher = UCameraDetacherComponent::Get(Owner); 

		// Bind delegates to detect when a cutscene starts
		Owner.OnPreSequencerControl.AddUFunction(this, n"OnPreCutsceneControl");
		User.OnOtherPlayerFullscreenCutscene.AddUFunction(this, n"OnOtherPlayerFullscreenCutscene");
		User.OnReset.AddUFunction(this, n"OnReset");
	}

	// Cutscene is about to start, actors have not been teleported yet. 
	// Cutscene cameras has not been activated.
	UFUNCTION(NotBlueprintCallable)
	void OnPreCutsceneControl(FHazePreSequencerControlParams Params)
	{
		if (IsBlocked())
			return;

		if (CameraDetacher == nullptr)		
			return; // We're not using a camera which can/needs to detach

		bIsCutsceneActive = true;
		bIsCutsceneBlendingIn = false;

		// Cutscene blend in is complete when current camera has blended out
		CameraDetacher.Camera.OnFinishedBlendingOut.AddUFunction(this, n"OnCutSceneBlendedIn");

		// Don't snap camera from teleports!
		FHazeCameraSettings Settings;
		Settings.bUseSnapOnTeleport = true;
		Settings.bSnapOnTeleport = false;
		PlayerOwner.ApplySpecificCameraSettings(Settings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend::Normal(0.f), this, EHazeCameraPriority::Low);

		if (CameraDetacher.Camera.CameraState == EHazeCameraState::BlendingOut)
			CutsceneBlendingIn();
		else
			CameraDetacher.Camera.OnDeactivated.AddUFunction(this, n"OnCutsceneCameraBlendingIn");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCutsceneCameraBlendingIn(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		CutsceneBlendingIn();
	}

	void CutsceneBlendingIn()
	{
		if (bIsCutsceneBlendingIn)
			return;
			
		bIsCutsceneBlendingIn = true;

		// Default camera needs to stop following player immediately and during
		// entire blend in, but follow with non-teleported velocity
		if (CameraDetacher != nullptr)		
			CameraDetacher.DetachedParent = nullptr;

		// Override camera clamps so we won't get snaps from that if snap rotating player
		FHazeCameraClampSettings NoClamps;
		NoClamps.bUseClampYawLeft = true;
		NoClamps.ClampYawLeft = 180.f;
		NoClamps.bUseClampYawRight = true;
		NoClamps.ClampYawRight = 180.f;
		NoClamps.bUseClampPitchDown = true;
		NoClamps.ClampPitchDown = 89.9f;
		NoClamps.bUseClampPitchUp = true;
		NoClamps.ClampPitchUp = 89.9f;
		PlayerOwner.ApplyCameraClampSettings(NoClamps, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::Cutscene);

		// If we're blending in to full screen then other player may need to handle this
		if (PlayerOwner.IsPendingFullscreen())
		{
			AHazePlayerCharacter OtherPlayer = PlayerOwner.OtherPlayer;
			UCameraUserComponent OtherUser = (OtherPlayer != nullptr) ? UCameraUserComponent::Get(OtherPlayer) : nullptr;
			if (ensure(OtherUser != nullptr))
				OtherUser.OnOtherPlayerFullscreenCutscene.Broadcast();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnOtherPlayerFullscreenCutscene()
	{
		if (IsBlocked())
			return;

		// Skip if we're already handling a blending in cutscene
		if (bIsCutsceneBlendingIn)
			return;

		// Handle this as if we're blending in cutscene ourselves 
		// Note that we'll deactivate when we don't have any screen space.
		if (!IsActive())
			OnPreCutsceneControl(FHazePreSequencerControlParams());
		CutsceneBlendingIn();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReset()
	{
		bIsCutsceneActive = false;
		if (!IsActive())
			Deactivate();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCutSceneBlendedIn(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		bIsCutsceneActive = false;
		if (!IsActive())
			Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!bIsCutsceneActive)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bIsCutsceneActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Deactivate();
	}
	void Deactivate()
	{
		CameraDetacher.Camera.OnDeactivated.Unbind(this, n"OnCutsceneCameraBlendingIn");
		PlayerOwner.ClearCameraSettingsByInstigator(this, 0.01f);

		if ((CameraDetacher != nullptr) && (CameraDetacher.Camera != nullptr))
		{
			// Camera detacher will automatically be reattached to default parent 
			// when finished blending out, but in case we deactivate for other reasons
			// make sure detacher is in a valid state
			if ((CameraDetacher.DetachedParent == nullptr) && 
			 	(CameraDetacher.Camera.GetCameraState() != EHazeCameraState::Inactive))
			 	CameraDetacher.DetachedParent = CameraDetacher.DefaultParent;
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
	{
		// Sanity checks in case camera was removed unexpectedly
		if (!System::IsValid(CameraDetacher) || !System::IsValid(CameraDetacher.Camera))
		{
			bIsCutsceneActive = false;
			return;			
		} 

		if (CameraDetacher.Camera.GetCameraState() == EHazeCameraState::BlendingOut)
		{
			// Cutscene camera has become active
			CutsceneBlendingIn();	
		}

		// Camera might not finish blending out before cutscene ends or might even not be 
		// activated at all if we have a cutscene with no camera track.
		// We can't check (CameraDetacher.Camera.GetCameraState() != EHazeCameraState::BlendingOut)
		// however since in some cutscenes the cutscene camera won't be activated until a tick into
		// the cutscene.
		if (CameraDetacher.Camera.GetCameraState() == EHazeCameraState::Inactive)
		{
			// Camera has finished blending out
			bIsCutsceneActive = false;
			return;
		}

		if (!PlayerOwner.bIsControlledByCutscene)
		{
			// Cutscene is over
			bIsCutsceneActive = false;
			return;
		}

		if (SceneView::GetPlayerViewSizePercentage(PlayerOwner) < 0.01f)
		{
			// No screen size, we can stop this
			bIsCutsceneActive = false;
			return;
		}

		if (bIsCutsceneBlendingIn)
		{
			// TODO: Follow along with predicted velocity. Might be needed when entering cutscenes with high velocity
			//CameraDetacher.SetWorldLocation(CameraDetacher.WorldLocation + PredictedVelocity * DeltaTime);
		}
	}
}