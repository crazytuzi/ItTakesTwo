
class ATugOfWarDeviceWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Settings")
	bool bIsLargeWheel = false;

	UPROPERTY(Category = "Settings")
	float RotationSpeed = 2.f;

	UPROPERTY(Category = "Setup", EditInstanceOnly)
	UStaticMesh MeshToUse;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetStaticMesh(MeshToUse);
	}
}