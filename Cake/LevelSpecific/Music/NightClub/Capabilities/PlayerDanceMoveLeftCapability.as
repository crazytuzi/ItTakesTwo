import Cake.LevelSpecific.Music.NightClub.Capabilities.PlayerDanceMoveBaseCapability;

class UPlayerDanceMoveLeftCapability : UPlayerDanceMoveBaseCapability
{
	default DanceActionName = ActionNames::DanceLeft;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Internal_ControlPreActivation(ActivationParams, RhythmComp.LeftFaceButton);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		Internal_OnActivated(ActivationParams, RhythmComp.bLeftHit);
	}
}
