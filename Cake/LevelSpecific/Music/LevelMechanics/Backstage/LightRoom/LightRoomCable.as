enum ECableType
{
	Cable01,
	Cable02,
	Cable03,
};

class ALightRoomCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ECableType CableType;

	UPROPERTY()
	TArray<UStaticMesh> MeshArray;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetStaticMesh(MeshArray[CableType]);		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetCableProgression(0.f);
	}

	void SetCableProgression(float NewProgression)
	{
		Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Offest", NewProgression);
	}
}