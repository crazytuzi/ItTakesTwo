import Cake.LevelSpecific.SnowGlobe.Sunchair.SunChairPlayerComponent;

class USunChairPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SunChairPlayerCancelCapability");
	default CapabilityTags.Add(n"SunChair");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USunChairPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USunChairPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bCanCancel)
        	return EHazeNetworkActivation::ActivateFromControl;
		
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.ShowPlayerCancel(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		PlayerComp.bCanCancel = false;
		PlayerComp.OnPlayerCancelChairEvent.Broadcast(Player);
		PlayerComp.HidePlayerCancel(Player);
	}
}