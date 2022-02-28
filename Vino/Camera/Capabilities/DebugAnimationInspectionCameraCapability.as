import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.CameraStatics;

#if TEST
class UDebugAnimationInspectionCameraCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default TickGroup = ECapabilityTickGroups::LastDemotable; // AFter camera view is finalized
    default CapabilityDebugCategory = CapabilityTags::Debug;

	AHazePlayerCharacter PlayerOwner = nullptr; 
	UCameraUserComponent User = nullptr;
	UCameraUserComponent OtherUser = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);
		OtherUser = UCameraUserComponent::Get(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleAnimationInspectionCamera", "ToggleAnimationInspectionCamera");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"Camera");
	}

	UFUNCTION()
	void ToggleAnimationInspectionCamera()
	{
		User.ToggleDebugDisplay(ECameraDebugDisplayType::AnimationInspect);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!User.ShouldDebugDisplay(ECameraDebugDisplayType::AnimationInspect))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!User.ShouldDebugDisplay(ECameraDebugDisplayType::AnimationInspect))
			return EHazeNetworkDeactivation::DeactivateLocal; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Other player should always activate this when we do
		OtherUser.EnableDebugDisplay(ECameraDebugDisplayType::AnimationInspect);

		// Activate default camera with animation inspection settings
		PlayerOwner.ApplyCameraSettings(User.DebugAnimationInspectionSettings, CameraBlend::Normal(), this, EHazeCameraPriority::Maximum);
		PlayerOwner.ActivateCamera(UHazeCameraComponent::Get(PlayerOwner),  CameraBlend::Normal(), this, EHazeCameraPriority::Script); // Don't override cutscene cams!
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Other player should always deactivate this when we do
		OtherUser.DisableDebugDisplay(ECameraDebugDisplayType::AnimationInspect);

		PlayerOwner.DeactivateCameraByInstigator(this);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerOwner.IsMay())
			PrintToScreenScaled("Animation Inspection camera active! Toggle in camera dev menu.", 0.f, FLinearColor::Red, 1.2f);
	}
}	
#endif
