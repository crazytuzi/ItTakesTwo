class AHopscotchDungeonChestFidgetSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent FidgetBase;
	default FidgetBase.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = FidgetBase)
	UStaticMeshComponent FidgetArms;
	default FidgetArms.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	bool bIsYellow = false;

	UPROPERTY()
	TArray<UStaticMesh> BaseMeshArray;

	UPROPERTY()
	TArray<UStaticMesh> ArmMeshArray;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FidgetBase.SetStaticMesh(bIsYellow ? BaseMeshArray[0] : BaseMeshArray[1]);
		FidgetArms.SetStaticMesh(bIsYellow ? ArmMeshArray[0] : ArmMeshArray[1]);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.AddLocalRotation(FRotator(0.f, 100.f * DeltaTime, 0.f));
		FidgetArms.AddLocalRotation(FRotator(0.f, 500.f * DeltaTime, 0.f));
	}
}