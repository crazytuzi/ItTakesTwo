import Effects.DecalTrail;

class AIceSkatingBlade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDecalTrailComponent Trail;

	UPROPERTY()
	bool bIsRightFoot = false;

	UPROPERTY()
	AHazePlayerCharacter Player;
}