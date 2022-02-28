import Cake.LevelSpecific.Music.NightClub.Capabilities.PlayerDanceMoveBaseCapability;

class UPlayerDanceMoveTopCapability : UPlayerDanceMoveBaseCapability
{
	default DanceActionName = ActionNames::DanceTop;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Internal_ControlPreActivation(ActivationParams, RhythmComp.TopFaceButton);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		Internal_OnActivated(ActivationParams, RhythmComp.bTopHit);
	}
}
