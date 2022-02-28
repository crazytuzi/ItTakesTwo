import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterableFlowerPlatform : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent FlowerMesh;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;

	UPROPERTY()
	TArray<FWaterLevelColor> Colors;

	UPROPERTY()
	FVector WiltedScale = FVector::OneVector;

	UPROPERTY()
	FVector WateredScale = FVector::OneVector;

	UPROPERTY()
	FVector WateredLocation;
	
	UPROPERTY()
	bool bPreviewFullyWatered = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewFullyWatered)
		{
			FlowerMesh.SetRelativeLocation(WateredLocation);
			SetActorScale3D(WateredScale);
		}
		else
		{
			FlowerMesh.SetRelativeLocation(FVector::ZeroVector);
			SetActorScale3D(WiltedScale);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector CurScale = FMath::Lerp(WiltedScale, WateredScale, WaterHoseImpactComp.CurrentWaterLevel);
		SetActorScale3D(CurScale);

		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, WateredLocation, WaterHoseImpactComp.CurrentWaterLevel);
		FlowerMesh.SetRelativeLocation(CurLoc);

		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(FlowerMesh, Colors);
	}
}