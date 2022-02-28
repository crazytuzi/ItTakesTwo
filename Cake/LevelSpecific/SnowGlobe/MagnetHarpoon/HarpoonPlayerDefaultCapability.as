import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
class UHarpoonPlayerDefaultCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerDefaultCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHarpoonPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHarpoonPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.MagnetHarpoonState == EMagnetHarpoonState::Default)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.MagnetHarpoonState != EMagnetHarpoonState::Default)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.ShowFirePrompt(Player);
	}
}