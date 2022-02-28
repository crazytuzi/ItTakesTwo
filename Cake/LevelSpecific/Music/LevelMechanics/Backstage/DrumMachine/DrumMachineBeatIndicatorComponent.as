class UDrumMachineBeatIndicatorComponent : UStaticMeshComponent
{
    //default StaticMesh = Asset("/Engine/BasicShapes/Cylinder.Cylinder");
    default RelativeScale3D = FVector(1.f, 1.f, 0.4f);
	default CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	UMaterialInterface BeatMaterial;
	UMaterialInterface PassiveMaterial; // Save default material on begin play

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PassiveMaterial = GetMaterial(0);
	}

	void Beat()
	{
		SetMaterial(0, BeatMaterial);
		System::ClearTimer(this, "EndBeat");
		System::SetTimer(this, n"EndBeat", 0.25f, false);
	}

	UFUNCTION()
	void EndBeat()
	{
		SetMaterial(0, PassiveMaterial);
	}
}