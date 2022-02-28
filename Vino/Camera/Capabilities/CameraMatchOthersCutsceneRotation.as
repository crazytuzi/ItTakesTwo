import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// Capability to match desired rotation of other players view rotation when other player is 
// controlled by cutscene and had full screen.
// Useful if you want to blend in split screen before cutscene is over and have both players 
// view behave as if cutscene controlled.
class UCameraMatchOthersCutsceneRotationCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	AHazePlayerCharacter OtherPlayer;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::NonControlled);
	default CapabilityTags.Add(n"CameraMatchOthersCutsceneRotation");

	// This should overwrite anything we get from input
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayer = PlayerUser.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (OtherPlayer.ActiveLevelSequenceActor == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (!OtherPlayer.ActiveLevelSequenceActor.bOtherPlayerMatchCameraRotation)
		 	return EHazeNetworkActivation::DontActivate;

		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		// We only only want this to apply when other player _exits_ from 
		// full screen, not at start of cutscenes.
		if (!SceneView::IsFullScreen() || (SceneView::GetFullScreenPlayer() != OtherPlayer))
		 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (OtherPlayer.ActiveLevelSequenceActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!OtherPlayer.ActiveLevelSequenceActor.bOtherPlayerMatchCameraRotation)
		 	return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);

		// Sensitivity should blend in after thís deactivates
		FHazeCameraSettings Settings;
		Settings.bUseSensitivityFactor = true;
		Settings.SensitivityFactor = 0.f;
		PlayerUser.ApplySpecificCameraSettings(Settings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend::Normal(), this, EHazeCameraPriority::Low);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
		
		// Initially slow sensitivity after this has been active
		PlayerUser.ClearCameraSettingsByInstigator(this, 2.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set desired rotation to othre players current view rotation
		FRotator ViewRot = PlayerUser.OtherPlayer.GetPlayerViewRotation();
		FRotator ViewRotLocal = User.WorldToLocalRotation(ViewRot);
		FRotator CurRotLocal = User.WorldToLocalRotation(User.GetDesiredRotation());
		User.AddDesiredRotation(ViewRotLocal - CurRotLocal);
	}
}
