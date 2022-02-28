import Cake.LevelSpecific.SnowGlobe.Curling.CurlingCameraManager;

class UCurlingCameraManagerDeactivateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingCameraManagerDeactivateCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	ACurlingCameraManager CameraManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraManager = Cast<ACurlingCameraManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CameraManager.CamManagerState == ECurlingCamManagerState::Inactive)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CameraManager.CamManagerState != ECurlingCamManagerState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraManager.SetBlockNonControlledCam(false);
	}
}