import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomActivationPoints;
class ALightRoomLightStripMesh : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	
	UPROPERTY()
	ALightRoomActivationPoints ActivationPoint;

	UPROPERTY()
	FLinearColor Black;

	UPROPERTY()
	FLinearColor Blue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationPoint.ActivationPointLightProgress.AddUFunction(this, n"AcitvationProgress");
		Mesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
	}

	UFUNCTION()
	void AcitvationProgress(float Progress)
	{
		Mesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black * (1.f - Progress) + Blue * Progress);
	}
}