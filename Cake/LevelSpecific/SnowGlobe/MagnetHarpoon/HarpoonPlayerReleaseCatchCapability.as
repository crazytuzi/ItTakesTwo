import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;

class UHarpoonPlayerReleaseCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerReleaseCatchCapability");
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
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && MagnetHarpoon.GetCanRelease() && PlayerComp.MagnetHarpoonState != EMagnetHarpoonState::ReleaseCatch)
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
		PlayerComp.MagnetHarpoonState = EMagnetHarpoonState::ReleaseCatch;

		PlayerComp.HidePrompts(Player);
		MagnetHarpoon.ReleaseCatch();

		PlayerComp.FiredHarpoon();
		Player.SetAnimBoolParam(n"FishReleased", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (MagnetHarpoon.GetCanRelease())
			MagnetHarpoon.SetCanRelease(false);
		
		PlayerComp.MagnetHarpoonState = EMagnetHarpoonState::Default;
	}
}