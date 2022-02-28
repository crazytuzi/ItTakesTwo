import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterableCorn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CornMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafRoot1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafRoot2;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafRoot3;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeafRoot4;

	UPROPERTY(DefaultComponent, Attach = LeafRoot1)
	UStaticMeshComponent Leaf1;

	UPROPERTY(DefaultComponent, Attach = LeafRoot2)
	UStaticMeshComponent Leaf2;

	UPROPERTY(DefaultComponent, Attach = LeafRoot3)
	UStaticMeshComponent Leaf3;

	UPROPERTY(DefaultComponent, Attach = LeafRoot4)
	UStaticMeshComponent Leaf4;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;

	UPROPERTY(NotVisible)
	TArray<USceneComponent> LeafRoots;

	float StartPitch = 60.f;

	UPROPERTY()
	bool bPreviewFullyWatered = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeafRoots.Empty();

		LeafRoots.Add(LeafRoot1);
		LeafRoots.Add(LeafRoot2);
		LeafRoots.Add(LeafRoot3);
		LeafRoots.Add(LeafRoot4);

		if (bPreviewFullyWatered)
		{
			for (USceneComponent CurLeafRoot : LeafRoots)
			{
				FRotator CurRot = FRotator(0.f, CurLeafRoot.RelativeRotation.Yaw, 0.f);
				CurLeafRoot.SetRelativeRotation(CurRot);
			}
		}
		else
		{
			for (USceneComponent CurLeafRoot : LeafRoots)
			{
				FRotator CurRot = FRotator(StartPitch, CurLeafRoot.RelativeRotation.Yaw, 0.f);
				CurLeafRoot.SetRelativeRotation(CurRot);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurPitch = FMath::Lerp(StartPitch, 0.f, WaterHoseComp.CurrentWaterLevel);

		for (USceneComponent CurLeafRoot : LeafRoots)
		{
			FRotator CurRot = FRotator(CurPitch, CurLeafRoot.RelativeRotation.Yaw, 0.f);
			CurLeafRoot.SetRelativeRotation(CurRot);	
		}
	}
}