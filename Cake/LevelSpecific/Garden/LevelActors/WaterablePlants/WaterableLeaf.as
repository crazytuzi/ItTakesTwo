import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterableLeaf : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafRoot;

	UPROPERTY(DefaultComponent, Attach = LeafRoot)
	UStaticMeshComponent LeafMesh;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;

	UPROPERTY(EditDefaultsOnly)
	TArray<FWaterLevelColor> Colors;

	UPROPERTY()
	bool bPreviewFullyWatered = false;

	UPROPERTY()
	float FullyWateredRotation = -175.f;

	UPROPERTY()
	float WitheredRotation = -80.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewFullyWatered)
			LeafRoot.SetRelativeRotation(FRotator(FullyWateredRotation, 0.f, 0.f));
		else
			LeafRoot.SetRelativeRotation(FRotator(WitheredRotation, 0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterHoseImpactComp.OnHitWithWater.AddUFunction(this, n"Watered");
	}

	UFUNCTION(NotBlueprintCallable)
	void Watered()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurPitch = FMath::Lerp(WitheredRotation, FullyWateredRotation, WaterHoseImpactComp.CurrentWaterLevel);
		LeafRoot.SetRelativeRotation(FRotator(CurPitch, 0.f, 0.f));

		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(LeafMesh, Colors);
	}
}