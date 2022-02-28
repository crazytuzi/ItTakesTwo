import Vino.Tilt.TiltComponent;

class AFloatingPillow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowMesh;

	UPROPERTY(DefaultComponent, Attach = PillowMesh)
	UTiltComponent TiltComp;
}