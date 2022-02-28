import Peanuts.Spline.SplineComponent;

int GetNumberOfSplinePointsFromMeshPath(AHazeActor TargetActor)
{
	if(TargetActor == nullptr)
	{
		return 0;
	}

	USplineMeshPathComponent SplineMeshPathComponent = USplineMeshPathComponent::Get(TargetActor);
	return SplineMeshPathComponent.NumberOfSplinePoints;
}

FVector GetSplineMeshPathLocationEnd(AHazeActor TargetActor)
{
	USplineMeshPathComponent SplineMeshPathComponent = USplineMeshPathComponent::Get(TargetActor);

	if(SplineMeshPathComponent == nullptr)
	{
		return FVector::ZeroVector;
	}

	return SplineMeshPathComponent.GetPathLocationEnd();
}

struct FSplineMeshInfo
{
	FVector LocalTangent = FVector::ZeroVector;
	FVector2D EndScale = FVector2D::UnitVector;
	FVector2D StartScale = FVector2D::UnitVector;
	USplineMeshComponent SplineMesh;
}

class USplineMeshPathComponent : UHazeSplineComponent
{
	default ClearSplinePoints();
	default AutoTangents = true;

	UPROPERTY(Category = BufferSettings)
	int Buffer = 64;

	UPROPERTY(Category = BufferSettings, meta = (ClampMin = 1.1, ClampMax = 2.0))
	float BufferIncreasePercent = 1.35f;

	UPROPERTY()
	bool bAutomaticallyUpdateBuffer = true;

	UPROPERTY(Category = Visual)
	UStaticMesh SplineMesh;

	UPROPERTY(Category = Visual)
	UMaterialInstance SplineMeshMaterial;

	int LevelOfDetailIndexLimit = 4;

	private TArray<USplineMeshComponent> ActiveSplineMeshes;
	private TArray<USplineMeshComponent> AllSplineMeshes;
	private TArray<FSplineMeshInfo> SplineMeshData;

	private AActor SplineMeshRoot;

	void Init_Editor(int InBuffer, AActor InSplineMeshRoot, const FVector& WorldStartLocation)
	{
		Internal_Init(InBuffer, InSplineMeshRoot, WorldStartLocation);
	}

	void Init(AActor InSplineMeshRoot, const FVector& WorldStartLocation)
	{
		Internal_Init(Buffer, InSplineMeshRoot, WorldStartLocation);
	}

	private void Internal_Init(int InBuffer, AActor InSplineMeshRoot, const FVector& WorldStartLocation)
	{
		if(SplineMeshMaterial == nullptr || SplineMesh == nullptr)
		{
			return;
		}

		SplineMeshRoot = InSplineMeshRoot;

		AddSplinePoint(WorldStartLocation, ESplineCoordinateSpace::World, false);
		for (int Index = 0, Count = InBuffer; Index < Count; ++Index)
		{
			USplineMeshComponent NewSplineMesh = USplineMeshComponent::Create(SplineMeshRoot);
			NewSplineMesh.SetMobility(EComponentMobility::Movable);
			NewSplineMesh.SetStaticMesh(SplineMesh);
			NewSplineMesh.SetMaterial(0, SplineMeshMaterial);
			NewSplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			NewSplineMesh.SetGenerateOverlapEvents(false);
			NewSplineMesh.SetVisibility(false);
			AllSplineMeshes.Add(NewSplineMesh);
		}

		SplineMeshData.SetNum(InBuffer);
	}

	FVector GetPathLocationStart() const
	{
		if(NumberOfSplinePoints == 0)
		{
			return FVector::ZeroVector;
		}

		return GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
	}

	void UpdateSplineMeshStretch(const FVector& StretchLocation)
	{
		const float Strength = 10.0f;
		for(int Index = 0; Index < ActiveSplineMeshes.Num(); ++Index)
		{
			USplineMeshComponent SplineMeshComp = ActiveSplineMeshes[Index];
			SplineMeshComp.SetColorParameterValueOnMaterialIndex(0, n"Item1", FLinearColor(StretchLocation.X, StretchLocation.Y, StretchLocation.Z, 40.0f));
			SplineMeshComp.SetColorParameterValueOnMaterialIndex(0, n"Strengths", FLinearColor(Strength, Strength, Strength, Strength));
		}
	}

	void ClearSplineStretch()
	{
		for(int Index = 0; Index < ActiveSplineMeshes.Num(); ++Index)
		{
			USplineMeshComponent SplineMeshComp = ActiveSplineMeshes[Index];
			SplineMeshComp.SetColorParameterValueOnMaterialIndex(0, n"Item1", FLinearColor(0.0f, 0.0f, 0.0f, 0.0f));
			SplineMeshComp.SetColorParameterValueOnMaterialIndex(0, n"Strengths", FLinearColor(0.0f, 0.0f, 0.0f, 0.0f));
		}
	}

	FVector GetPathLocationEnd() const
	{
		if(NumberOfSplinePoints == 0)
		{
			return FVector::ZeroVector;
		}

		return GetLocationAtSplinePoint(NumberOfSplinePoints - 1, ESplineCoordinateSpace::World);
	}

	void UpdateSplineMeshes()
	{
		Internal_UpdateSplineMeshes(0, ActiveSplineMeshes.Num());
	}

	private void UpdateSplineMeshesWithRange(int StartIndex, int EndIndex)
	{
		Internal_UpdateSplineMeshes(StartIndex, EndIndex);
	}

	private void Internal_UpdateSplineMeshes(int StartIndex, int EndIndex)
	{		
		for(int Index = StartIndex, Count = EndIndex; Index < Count; ++Index)
		{
			USplineMeshComponent SplineMeshComp = ActiveSplineMeshes[Index];
			FSplineMeshInfo SplineMeshInfo = SplineMeshData[Index];

			const FVector StartLocation = GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			const FVector StartTangent = GetTangentAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			const FVector EndLocation = GetLocationAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);
			const FVector EndTangent = GetTangentAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);

			SplineMeshComp.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, false);
		}
	}

	FVector GetLocalTangent(int Index) const
	{
		return SplineMeshData[Index].LocalTangent;
	}

	void SetLocalSplineMeshTangent(int Index, FVector InLocalTangent)
	{
		SplineMeshData[Index].LocalTangent = InLocalTangent;
	}

	bool HasFreeSplineMesh() const
	{
		return ActiveSplineMeshes.Num() < AllSplineMeshes.Num();
	}

	private void IncreaseSplineMeshBuffer()
	{
		int BufferIncrease = int((float(Buffer) * BufferIncreasePercent));

		for (int Index = 0, Count = BufferIncrease; Index < Count; ++Index)
		{
			USplineMeshComponent NewSplineMesh = USplineMeshComponent::Create(SplineMeshRoot);
			NewSplineMesh.SetMobility(EComponentMobility::Movable);
			NewSplineMesh.SetStaticMesh(SplineMesh);
			NewSplineMesh.SetMaterial(0, SplineMeshMaterial);
			NewSplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			NewSplineMesh.SetGenerateOverlapEvents(false);
			NewSplineMesh.SetVisibility(false);
			AllSplineMeshes.Add(NewSplineMesh);
			SplineMeshData.Add(FSplineMeshInfo());
		}

		Buffer += BufferIncrease;
	}

	void AddSplinePointStart(FVector SplinePointToAdd)
	{
		AddSplinePointAtIndex(SplinePointToAdd, 0, ESplineCoordinateSpace::World, false);
	}

	void AddSplinePointEnd(FVector SplinePointToAdd)
	{
		AddSplinePoint(SplinePointToAdd, ESplineCoordinateSpace::World, false);
	}

	private bool CanAddSegment()
	{
		if(!HasFreeSplineMesh())
		{
			if(bAutomaticallyUpdateBuffer)
			{
				IncreaseSplineMeshBuffer();
			}
			else
			{
				devEnsureAlways(true, Name + ": SplineMeshBuffer limit exceeded.");
				return false;
			}
		}

		return true;
	}

	void AddSplineMesh()
	{
		USplineMeshComponent NewSplineMesh = AllSplineMeshes[ActiveSplineMeshes.Num()];
		NewSplineMesh.SetVisibility(true);
		ActiveSplineMeshes.Add(NewSplineMesh);
	}

	void AddSegmentStart(const FVector& PointToAdd)
	{
		if(!CanAddSegment())
		{
			return;
		}

		AddSplinePointStart(PointToAdd);
		AddSplineMesh();
	}

	void AddSegmentEnd(const FVector& PointToAdd)
	{
		if(!CanAddSegment())
		{
			return;
		}

		AddSplinePointEnd(PointToAdd);
		AddSplineMesh();
	}

	void AddSegmentAtIndex(const FVector& PointToAdd, int Index)
	{
		if(Index < 0 || Index >= NumberOfSplinePoints)
		{
			return;
		}

		if(Index == 0)
		{
			AddSegmentStart(PointToAdd);
		}
		else if(Index == (NumberOfSplinePoints - 1))
		{
			AddSegmentEnd(PointToAdd);
		}
		else
		{
			if(!CanAddSegment())
			{
				return;
			}

			AddSplinePointAtIndex(PointToAdd, Index, ESplineCoordinateSpace::World, true);
			AddSplineMesh();
			UpdateSplineMeshes();
		}
	}

	void RemoveSegmentStart()
	{
		RemoveSplinePoint(0, true);
		RemoveSplineMesh();
	}

	void RemoveSegmentEnd()
	{
		RemoveSplinePoint(NumberOfSplinePoints - 1, true);
		RemoveSplineMesh();
	}

	void RemoveSegmentAtIndex(int Index)
	{
		if(Index < 0 || Index > (NumberOfSplinePoints - 1))
		{
			return;
		}

		RemoveSplinePoint(Index, true);
		RemoveSplineMesh();
	}
	
	private void RemoveSplineMesh()
	{
		if(ActiveSplineMeshes.Num() == 0)
		{
			return;
		}

		ActiveSplineMeshes.Last().SetVisibility(false);
		ActiveSplineMeshes.RemoveAt(ActiveSplineMeshes.Num() - 1);
	}

	void ClearSplineMeshPath()
	{
		ClearSplinePoints();
		
		for(USplineMeshComponent SplineMeshComp : ActiveSplineMeshes)
		{
			SplineMeshComp.SetVisibility(false);
		}

		ActiveSplineMeshes.Empty();
	}

	void ClearBuffer()
	{
		ClearSplineMeshPath();

		for(USplineMeshComponent CurrentSplineMesh : AllSplineMeshes)
		{
			CurrentSplineMesh.DestroyComponent(SplineMeshRoot);
		}

		AllSplineMeshes.Empty();
	}
}
