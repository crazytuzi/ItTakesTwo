import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class UHarpoonPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerCancelCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHarpoonPlayerComponent PlayerComp;
	AMagnetHarpoonActor MagnetHarpoon;

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
		if (WasActionStarted(ActionNames::Cancel) && MagnetHarpoon.HarpoonSpearState == EHarpoonSpearState::Still)
        	return EHazeNetworkActivation::ActivateFromControl;

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
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		PlayerComp.OnPlayerCancelledMagnetHarpoon.Broadcast(Player);
		PlayerComp.MagnetHarpoonState = EMagnetHarpoonState::Default;
		// MagnetHarpoon.bPlayerReleasedCatch = false;
	}
}