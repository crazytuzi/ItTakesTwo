import Cake.LevelSpecific.SnowGlobe.Curling.CurlingEndSessionManager;

class UCurlingEndSessionDoorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingEndSessionDoorCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingEndSessionManager CurlingEndSessionManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingEndSessionManager = Cast<ACurlingEndSessionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CurlingEndSessionManager.bCanActivateDoor)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!CurlingEndSessionManager.bCanActivateDoor)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}

}