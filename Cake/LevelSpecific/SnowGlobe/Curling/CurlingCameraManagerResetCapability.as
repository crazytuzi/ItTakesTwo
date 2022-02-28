import Cake.LevelSpecific.SnowGlobe.Curling.CurlingCameraManager;

class UCurlingCameraManagerResetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingCameraManagerResetCapability");

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
		if (CameraManager.CamManagerState == ECurlingCamManagerState::Following)
        	return EHazeNetworkActivation::ActivateLocal;
			
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
			return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}
}