namespace ClockworkLastBoss
{
	UFUNCTION()
	void SetNewExplosionFocus(AHazePlayerCharacter TargetPlayer, AHazeActor NewTargetActor)
	{
		UClockworkLastBossMayExplosionComponent Comp = UClockworkLastBossMayExplosionComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			Comp.FocusTargetActor = NewTargetActor;
		}
	}
}

class UClockworkLastBossMayExplosionComponent : UActorComponent
{
	AHazeActor FocusTargetActor;
}