import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

class UClockworkBirdFlyingComponent : UActorComponent
{
	UPROPERTY()
	AClockworkBird MountedBird;

	UPROPERTY()
	TArray<AClockworkBird> CanCallBirds;

	UPROPERTY()
	TArray<AHazeActor> SpeedLimitActors;

	TArray<AActor> CallBirdPositions;
};