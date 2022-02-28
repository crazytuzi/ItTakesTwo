class AFerrisWheelCarActor : AHazeActor
{
	UPROPERTY()
	AHazeActor Posiiton;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		SetActorLocation(Posiiton.ActorLocation);
	}
}