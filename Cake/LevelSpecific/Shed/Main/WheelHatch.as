class AWheelHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HatchAkComp;
	
	UPROPERTY()
	bool GameActive = false;

}