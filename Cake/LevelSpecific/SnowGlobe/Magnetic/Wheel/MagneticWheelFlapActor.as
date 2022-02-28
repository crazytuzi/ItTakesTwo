import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

UCLASS(Abstract)
class AMagneticWheelFlapActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UMagnetGenericComponent MagneticComponent;
}