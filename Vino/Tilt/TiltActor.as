import Vino.Tilt.TiltComponent;
class ATiltActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTiltComponent TiltComp;
}