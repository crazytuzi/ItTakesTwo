import Cake.LevelSpecific.SnowGlobe.Curling.CurlingEndSessionManager;
class UCurlingEndSessionPullCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingEndSessionPullCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingEndSessionManager CurlingEndSessionManager;

	float ImpulseForce = 95.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingEndSessionManager = Cast<ACurlingEndSessionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CurlingEndSessionManager.bActivateEndSession)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!CurlingEndSessionManager.bActivateEndSession)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurlingEndSessionManager.bCanActivateDoor = true;
		CurlingEndSessionManager.SetSystemState(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CurlingEndSessionManager.bCanOpenDoor = false;
		CurlingEndSessionManager.SetSystemState(false);
		CurlingEndSessionManager.AcceleratedStoneSpeed.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		for (ACurlingStone Stone : CurlingEndSessionManager.EndSessionStoneArray)
		{
			Stone.AddImpulse(CurlingEndSessionManager.ActorForwardVector * ImpulseForce);
		}
	}
}