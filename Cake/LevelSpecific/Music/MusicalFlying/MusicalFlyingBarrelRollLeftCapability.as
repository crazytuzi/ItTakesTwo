import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingBarrelRollCapability;

UCLASS(Deprecated)
class UMusicalFlyingBarrelRollLeftCapability : UMusicalFlyingBarrelRollCapability
{
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		FlyingComp.BarrellRollState = EMusicalFlyingBarrelRoll::Left;
	}

	bool OnButtonPressed() const { return WasActionStarted(ActionNames::MusicFlyingTightTurnLeft); }
}
