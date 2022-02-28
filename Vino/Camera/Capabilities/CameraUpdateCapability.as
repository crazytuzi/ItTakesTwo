import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// This updates the entire camera system, including all active camera parent components. 
// If blocked, camera view will remain static.
class UCameraUpdateCapability : UHazeCapability
{
	UCameraUserComponent User;

	EHazeCameraChaseAssistance PreviousChaseAssistance = EHazeCameraChaseAssistance::Invalid;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault"); 

    default CapabilityDebugCategory = CameraTags::Camera;

	// Updating in last demotable gives some minor glitches when framerate is uneven
	default TickGroup = ECapabilityTickGroups::PostWork; 
	default TickGroupOrder = 200;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (User.DeferredSnap != EHazeCameraSnapType::None)
		{
			// Snap camera before updating. This means all other capabilities etc has had a chance to position the user,
			// apply settings, desired rotation and anything else which can influence the camera before snap takes place.
			FVector Direction = User.DeferredSnapCameraDirection;
			if ((User.DeferredSnap == EHazeCameraSnapType::BehindUser) && (User.Owner != nullptr))
				Direction = User.Owner.ActorTransform.TransformVector(Direction);
				
			User.SnapCamera(Direction);
			User.DeferredSnap = EHazeCameraSnapType::None;
		}

		UpdateChaseAssistance(User.PlayerOwner.GetChaseAssistanceStrength());

		User.Update(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PreviousChaseAssistance = EHazeCameraChaseAssistance::Invalid;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UpdateChaseAssistance(EHazeCameraChaseAssistance::Invalid);	
	}

	void UpdateChaseAssistance(EHazeCameraChaseAssistance ChaseAssistance)
	{
		if (ChaseAssistance == PreviousChaseAssistance)
			return;

		// Update chase settings
		User.PlayerOwner.ClearSettingsByInstigator(this);
		if (ChaseAssistance == EHazeCameraChaseAssistance::Weak)
		{
			User.PlayerOwner.ApplySettings(User.DefaultLazyChaseSettingsWeak, this, EHazeSettingsPriority::Defaults);
		}
		else if (ChaseAssistance == EHazeCameraChaseAssistance::Strong)
		{
			User.PlayerOwner.ApplySettings(User.DefaultLazyChaseSettingsStrong, this, EHazeSettingsPriority::Defaults);
		}
		else if (ChaseAssistance == EHazeCameraChaseAssistance::None)
		{
			// Apply weak settings for those capabilities that use chase settings but should be active even though chase assistance 
			// has been turned off in settings, then turn off the 'use optional chase assistance' setting.
			User.PlayerOwner.ApplySettings(User.DefaultLazyChaseSettingsWeak, this, EHazeSettingsPriority::Defaults);
			UCameraLazyChaseSettings::SetbUseOptionalChaseAssistance(User.PlayerOwner, false, this, EHazeSettingsPriority::Defaults);
		}

		// Update capability blocks	
		if (ChaseAssistance == EHazeCameraChaseAssistance::None)
			User.PlayerOwner.BlockCapabilities(CameraTags::OptionalChaseAssistance, this);
		else if (PreviousChaseAssistance == EHazeCameraChaseAssistance::None)
			User.PlayerOwner.UnblockCapabilities(CameraTags::OptionalChaseAssistance, this);
		
		PreviousChaseAssistance = ChaseAssistance;
	}
}