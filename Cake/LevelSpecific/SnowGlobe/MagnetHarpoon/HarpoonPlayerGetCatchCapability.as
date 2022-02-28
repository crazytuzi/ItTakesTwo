import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class UHarpoonPlayerGetCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerGetCatchCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHarpoonPlayerComponent PlayerComp;
	AMagnetHarpoonActor MagnetHarpoon;

	FHazeAcceleratedFloat AccelSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHarpoonPlayerComponent::Get(Player);
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(GetAttributeObject(n"MagnetHarpoon"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.MagnetHarpoonState == EMagnetHarpoonState::GotCatch)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.MagnetHarpoonState != EMagnetHarpoonState::GotCatch)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.ShowReleasePrompt(Player);
	}
}