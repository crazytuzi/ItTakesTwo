class AMeasuringTool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	UPROPERTY()
	UStaticMesh LineMesh = Asset("/Game/Environment/BasicShapes/Plane.Plane");
	
	UPROPERTY()
	TArray<FMeasurementData> Measurements;
	UPROPERTY()
	TArray<UStaticMeshComponent> MeshComponents;

	default bRunConstructionScriptOnDrag = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CreateLines();
	}

	void CreateLines()
	{
		MeshComponents.Empty();

		float Distance = TargetLocation.Size();

		if (Measurements.Num() <= 0)
			return;

		int NumberOfLines = Distance / Measurements[0].Distance;

		for (int Index = 0, Count = NumberOfLines; Index <= Count; ++Index)
		{
			UStaticMeshComponent LineMeshComp = UStaticMeshComponent::Create(this);
			MeshComponents.Add(LineMeshComp);
			LineMeshComp.SetStaticMesh(LineMesh);
			
			LineMeshComp.SetRelativeScale3D(FVector(Measurements[0].LineThickness * 0.01f, LineMeshComp.RelativeScale3D.Y, LineMeshComp.RelativeScale3D.Z));
			LineMeshComp.SetRelativeLocation(TargetLocation.GetSafeNormal() * Measurements[0].Distance * Index);

			FRotator Rotation = Math::MakeRotFromXZ(TargetLocation, FVector::UpVector);
			LineMeshComp.SetRelativeRotation(Rotation);
		}
	}
}

struct FMeasurementData
{
	UPROPERTY()
	int Distance = 100;
	UPROPERTY()
	FLinearColor LineColour = FLinearColor::White;
	UPROPERTY()
	float LineThickness = 5.f;
	UPROPERTY()
	int Priority = 5;
}