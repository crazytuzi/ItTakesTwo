import Cake.LevelSpecific.Music.NightClub.Capabilities.PlayerDanceMoveBaseCapability;


class UPlayerDanceMoveRightCapability : UPlayerDanceMoveBaseCapability
{
	default DanceActionName = ActionNames::DanceRight;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Internal_ControlPreActivation(ActivationParams, RhythmComp.RightFaceButton);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		Internal_OnActivated(ActivationParams, RhythmComp.bRightHit);
	}
}
