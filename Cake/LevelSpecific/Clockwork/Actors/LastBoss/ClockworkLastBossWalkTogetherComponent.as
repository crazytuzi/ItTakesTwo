import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossWalkTogetherManager;
UFUNCTION()
void SetClockworkworkWalkTogetherManager(AClockworkLastBossWalkTogetherManager Manager, AHazePlayerCharacter Player)
{
	UClockworkLastBossWalkTogetherComponent Comp = UClockworkLastBossWalkTogetherComponent::Get(Player);
	if (Comp != nullptr)
		Comp.WalkTogetherManager = Manager;
}

class UClockworkLastBossWalkTogetherComponent : UActorComponent
{
	AClockworkLastBossWalkTogetherManager WalkTogetherManager;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}