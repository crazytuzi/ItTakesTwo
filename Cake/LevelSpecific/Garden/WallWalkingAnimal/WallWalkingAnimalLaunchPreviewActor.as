class AWallWalkingAnimalLaunchPreviewActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(NotEditable)
	UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMaterial = Mesh.CreateDynamicMaterialInstance(0);
	}

	void SetIsValid(bool bNewStatus)
	{
		DynamicMaterial.SetScalarParameterValue(n"IsValidTarget", bNewStatus ? 1.f : 0.f);
	}
}