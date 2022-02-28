
class UDataAssetCloud : UDataAsset
{
    
}

class ACloud : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;
    default Mesh.StaticMesh = Asset("/Game/Effects/Environment/Clouds/CloudMesh.CloudMesh");
	UMaterialInstance Material = Asset("/Game/Effects/Environment/Clouds/WitnessCloud_Inst.WitnessCloud_Inst");

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Billboard;
    default Billboard.StaticMesh = Asset("/Game/Effects/Environment/Clouds/CloudPlane.CloudPlane");
	UMaterialInstance BillboardMaterial = Asset("/Game/Effects/Environment/Clouds/CloudPlane_mat_Inst.CloudPlane_mat_Inst");
}