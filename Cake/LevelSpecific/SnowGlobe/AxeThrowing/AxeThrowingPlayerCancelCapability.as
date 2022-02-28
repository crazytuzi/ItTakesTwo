import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;

class UAxeThrowingPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingPlayerCancelCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{

	} 

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}