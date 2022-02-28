import Vino.Bounce.BounceComponent;
import Vino.Tilt.TiltComponent;

UCLASS(Abstract)
class AFloatingPlank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlankRoot;

	UPROPERTY(DefaultComponent, Attach = PlankRoot)
	UStaticMeshComponent PlankMesh;

	UPROPERTY(DefaultComponent, Attach = PlankRoot)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, Attach = PlankRoot)
	UBounceComponent BounceComp;
}