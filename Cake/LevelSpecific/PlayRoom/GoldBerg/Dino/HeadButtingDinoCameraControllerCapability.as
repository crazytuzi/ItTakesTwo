import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
class UHeadButtingDinoCameraControllerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DinoCameraController");

	AHeadButtingDino ControlledDino;
	AHazePlayerCharacter Player;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettings;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AHeadButtingDino HeadbuttingDino = Cast<AHeadButtingDino>(GetAttributeObject(n"HeadbuttingDino"));

		if (HeadbuttingDino != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"LeaveDino"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ControlledDino = Cast<AHeadButtingDino>(GetAttributeObject(n"HeadbuttingDino"));
		FHazeCameraBlendSettings BlendSettings;
		Player.ApplyCameraSettings(CamSettings, BlendSettings, this);
		ControlledDino.Camera.ActivateCamera(Player, FHazeCameraBlendSettings(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 2);
	}
}