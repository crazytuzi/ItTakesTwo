import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingBarrelRollCapability;

UCLASS(Deprecated)
class UMusicalFlyingBarrelRollRightCapability : UMusicalFlyingBarrelRollCapability
{
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		FlyingComp.BarrellRollState = EMusicalFlyingBarrelRoll::Right;
	}

	bool OnButtonPressed() const { return WasActionStarted(ActionNames::MusicFlyingTightTurnRight); }
}
