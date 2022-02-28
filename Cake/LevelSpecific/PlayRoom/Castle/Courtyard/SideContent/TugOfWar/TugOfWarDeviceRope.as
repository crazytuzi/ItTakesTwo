
class ATugOfWarDeviceRope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	
	UPROPERTY(Category = "Setup", EditInstanceOnly)
	UStaticMesh MeshToUse;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UMaterialInstance TilingMaterial;

	UPROPERTY(Category = "Settings")
	float Tiling = 4;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetStaticMesh(MeshToUse);

		if(TilingMaterial != nullptr)
			Mesh.SetMaterial(0, TilingMaterial);

		UMaterialInstanceDynamic MatInst = Mesh.CreateDynamicMaterialInstance(0);
		MatInst.SetScalarParameterValue(n"Tiling X", Tiling);
	}
}