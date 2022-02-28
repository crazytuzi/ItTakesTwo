import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
class SnailaceSnailIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnailRace");
	default CapabilityTags.Add(n"SnailRaceCapability");
	default CapabilityDebugCategory = n"SnailRace";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnailRaceSnailActor Snail;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snail = Cast<ASnailRaceSnailActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
	}
}