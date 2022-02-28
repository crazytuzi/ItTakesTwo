class ASkiLiftTower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	ASkiLiftTower NextTower;
}

