class AQueenReloadArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Child01;

	UPROPERTY(DefaultComponent, Attach = Child01)
	USceneComponent Child02;
}