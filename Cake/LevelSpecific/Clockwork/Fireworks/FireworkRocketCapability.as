import Cake.LevelSpecific.Clockwork.Fireworks.FireworkRocket;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworksManager;

class UFireworkRocketCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FireworkRocketCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AFireworkRocket FireworkRocket;
	AFireworksManager FireworkManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FireworkRocket = Cast<AFireworkRocket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}