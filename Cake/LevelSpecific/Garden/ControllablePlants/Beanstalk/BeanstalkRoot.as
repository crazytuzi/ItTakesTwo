class ABeanstalkRoot : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;
}