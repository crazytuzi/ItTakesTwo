import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterableSunflower : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SunflowerBase;

	UPROPERTY(DefaultComponent, Attach = SunFlowerBase)
	UStaticMeshComponent SunflowerStem;

	UPROPERTY(DefaultComponent, Attach = SunFlowerBase)
	UStaticMeshComponent SunflowerHead;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurHeadRot = FMath::Lerp(95.f, 0.f, WaterHoseImpactComp.CurrentWaterLevel);
		SunflowerHead.SetRelativeRotation(FRotator(0.f, 0.f, CurHeadRot));
	}
}