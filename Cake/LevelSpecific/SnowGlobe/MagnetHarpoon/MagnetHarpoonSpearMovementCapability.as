import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class UMagnetHarpoonSpearMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonSpearMovementCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor MagnetHarpoon;
	AHazePlayerCharacter OurUsingPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagnetHarpoon.HarpoonSpearState == EHarpoonSpearState::Still/* || !MagnetHarpoon.CanPendingFire()*/)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetHarpoon.HarpoonSpearState == EHarpoonSpearState::Still)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MagnetHarpoon.UsingPlayer);
		OutParams.AddObject(n"NetPlayer", Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OurUsingPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"NetPlayer"));

		if (OurUsingPlayer != nullptr)
			OurUsingPlayer.BlockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagnetHarpoon.HarpoonSpearSkel.WorldLocation = MagnetHarpoon.SpearTargetLocation;

		if (OurUsingPlayer != nullptr)
			OurUsingPlayer.UnblockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MagnetHarpoon.HarpoonSpearSkel.WorldLocation = FMath::VInterpConstantTo(MagnetHarpoon.HarpoonSpearSkel.WorldLocation, MagnetHarpoon.SpearTargetLocation, DeltaTime, MagnetHarpoon.AccelSpearSpeed.Value);
	}
}