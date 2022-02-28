import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;

class UIceRaceStartCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"IceRace";

	default CapabilityTags.Add(n"IceRace");
	default CapabilityTags.Add(n"IceRaceStart");

	UIceRaceComponent IceRaceComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		IceRaceComponent = UIceRaceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IceRaceComponent.bInStartPosition)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IceRaceComponent.bInStartPosition)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}
}