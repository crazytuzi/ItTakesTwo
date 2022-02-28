class AFidgetspinnerLandingpad : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent, Attach = Mesh)
    UBoxComponent BoxCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
}
