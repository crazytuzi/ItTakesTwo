import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Capabilities.LookatFocusPointComponent;

class ULookAtFocusPointCapability: UHazeCapability
{
	ULookatFocusPointComponent POIComp;
	FLookatFocusPointData Data;
	TArray<FName> BlockList;
	AHazePlayerCharacter Player;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::PointOfInterest);
	default CapabilityTags.Add(CameraTags::LookatFocusPoint);

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		POIComp = ULookatFocusPointComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"LookAtFocusPoint"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}	

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration > Data.Duration && Data.Duration != -1)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		if(!UHazeActiveCameraUserComponent::Get(Player).HasPointOfInterest(EHazePointOfInterestType::Forced))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		if (IsActioning(n"StopLookatFocusPoint"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else 
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		POIComp.Settings.GetSettingsParams(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"StopLookatFocusPoint");
		POIComp.Settings.SetFromActivationParams(ActivationParams);
		Data = POIComp.Settings;

		BlockList = POIComp.Blocklist;

		if (Data.ShowLetterbox)
		{
			Player.SetShowLetterbox(true);
		}

		FHazeCameraBlendSettings Blendsettings; 
		Blendsettings.BlendTime = Data.POIBlendTime;
		Player.ApplyFieldOfView(Data.FOV, Blendsettings, this);

		for (auto tag : BlockList)
		{
			Player.BlockCapabilities(tag, this);
		}

		if (POIComp.Settings.OverrideCameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(POIComp.Settings.OverrideCameraSettings, Blendsettings, this);
		}

		FHazeFocusTarget FocusTarget;
		FocusTarget.Actor = Data.Actor;
		FocusTarget.Component = Data.Component;

		FHazePointOfInterest POI;
		POI.Duration = Data.Duration;
		POI.FocusTarget = FocusTarget;
		POI.bClearOnInput = Data.ClearOnInput;

		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(n"LookAtFocusPoint");

		for (auto tag : BlockList)
		{
			Player.UnblockCapabilities(tag, this);
		}

		if (Data.ShowLetterbox)
		{
			Player.SetShowLetterbox(false);
		}
		
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearFieldOfViewByInstigator(this);

		POIComp.ClearData();
	}
}