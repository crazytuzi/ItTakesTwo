class AWindupCassette : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CassetteMesh;

	
}