import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;

class UHarpoonPlayerLocoCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerLocoCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMagnetHarpoonActor MagnetHarpoon;
	UHarpoonPlayerComponent PlayerComp;

	FHazeRequestLocomotionData AnimRequest;

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
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AnimRequest.AnimationTag = n"MagnetHarpoon";

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);

		if (Player == Game::May)
			Player.AddLocomotionFeature(PlayerComp.HarpoonFeatureMay);
		else
			Player.AddLocomotionFeature(PlayerComp.HarpoonFeatureCody);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Player == Game::Cody)
			Player.RemoveLocomotionFeature(PlayerComp.HarpoonFeatureMay);
		else
			Player.RemoveLocomotionFeature(PlayerComp.HarpoonFeatureCody);
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(AnimRequest);
	}
}