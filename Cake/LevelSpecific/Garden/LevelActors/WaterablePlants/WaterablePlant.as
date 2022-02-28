import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterablePlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlantMesh;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}
}