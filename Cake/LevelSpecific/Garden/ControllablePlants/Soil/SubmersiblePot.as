import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilComponent;

UCLASS(Abstract)
class ASubmersiblePot : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PotMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SoilMesh;

	UPROPERTY(DefaultComponent)
	USubmersibleSoilComponent SoilComp;
}
