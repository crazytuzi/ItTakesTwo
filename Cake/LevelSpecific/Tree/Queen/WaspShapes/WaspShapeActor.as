import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspShapeSpawner;

UCLASS(Abstract)
class AWaspShapeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UWaspShapeSpawner WaspSpawner;
	
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Shape;

	UPROPERTY()
	float SplineScaleMultiplier = 1;

	UPROPERTY()
	float Damage = 0.5f;

	UPROPERTY(NotEditable, Category = "EditorOnly")
	TArray<USplineMeshComponent> SplineMeshes;

	UPROPERTY(Category = "EditorOnly")
	UStaticMesh SplineDebugMesh = Asset("/Game/Editor/Visualizers/SplineCylinder.SplineCylinder");

	UPROPERTY(Category = "EditorOnly")
	UMaterial SplineDebugMaterial = Asset("/Game/Editor/Visualizers/SwimmingStreamDebugMaterial.SwimmingStreamDebugMaterial");

	UPROPERTY()
	FVector SplineMeshWorldOffset;

	UPROPERTY()
	bool bDebugStartActive = false;

	bool bIsSpawning = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AddSplineMeshes();
		UpdateSplineMeshes();		
	}

	void AddSplineMeshes()
	{
		SplineMeshes.Empty();

		int SplineMeshCount = Shape.GetNumberOfSplinePoints() - 1;
		if ( Shape.IsClosedLoop())
			SplineMeshCount += 1;

		for (int Index = 0, Count = SplineMeshCount; Index < Count; ++ Index)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this);
			SplineMesh.SetStaticMesh(SplineDebugMesh);
			SplineMesh.SetMaterial(0, SplineDebugMaterial);		
			SplineMesh.ForwardAxis = ESplineMeshAxis::X;
			SplineMeshes.Add(SplineMesh);
		}
	}

	void UpdateSplineMeshes()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			int StartIndex = SplineMeshes.FindIndex(SplineMesh);
			int EndIndex = StartIndex + 1;

			if (Shape.IsClosedLoop() && EndIndex >= Shape.GetNumberOfSplinePoints())
				EndIndex = 0;

			FVector StartLocation = Shape.GetLocationAtSplinePoint(StartIndex, ESplineCoordinateSpace::Local) * Shape.RelativeScale3D + SplineMeshWorldOffset;
			FVector StartTangent = Shape.GetTangentAtSplinePoint(StartIndex, ESplineCoordinateSpace::Local)  * Shape.RelativeScale3D  + SplineMeshWorldOffset;
			FVector EndLocation = Shape.GetLocationAtSplinePoint(EndIndex, ESplineCoordinateSpace::Local)  * Shape.RelativeScale3D  + SplineMeshWorldOffset;
			FVector EndTangent = Shape.GetTangentAtSplinePoint(EndIndex, ESplineCoordinateSpace::Local)  * Shape.RelativeScale3D  + SplineMeshWorldOffset;
			SplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);

			FVector StartScale = FVector::OneVector * Shape.GetScaleAtSplinePoint(StartIndex) * SplineScaleMultiplier;
			FVector EndScale = FVector::OneVector * Shape.GetScaleAtSplinePoint(EndIndex) * SplineScaleMultiplier;

			SplineMesh.SetStartScale(FVector2D(StartScale.Z, StartScale.Z));
			SplineMesh.SetEndScale(FVector2D(EndScale.Z, EndScale.Z));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bDebugStartActive)
		{
			WaspSpawner.bShouldIterate = true;	
			StartSpawning();
		}
		else
		{
			SetActorHiddenInGame(true);
			WaspSpawner.bShouldIterate = false;
		}
	}

	UFUNCTION()
	void StartSpawning()
	{
		if (bIsSpawning)
		{
			StopSpawning();
		}
		
		WaspSpawner.StartSpawning();
		WaspSpawner.Damage = Damage;
		SetActorHiddenInGame(false);
		bIsSpawning = true;
	}

	UFUNCTION()
	void StopSpawning()
	{
		SetActorHiddenInGame(true);
		WaspSpawner.StopSpawning();
		bIsSpawning = false;
	}
}