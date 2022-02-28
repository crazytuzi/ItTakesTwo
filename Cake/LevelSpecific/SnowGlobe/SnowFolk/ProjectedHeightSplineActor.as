import Cake.LevelSpecific.SnowGlobe.Snowfolk.ProjectedHeightSplineComponent;

class UConnectedSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UConnectedSplineVisualizerComponent::StaticClass();

	TArray<AProjectedHeightSplineActor> SplineActorsToVisualize;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ProjectedHeightSplineActor = Cast<AProjectedHeightSplineActor>(Component.Owner);
		if (ProjectedHeightSplineActor == nullptr)
			return;

		SplineActorsToVisualize.Empty();

		SplineActorsToVisualize.Add(ProjectedHeightSplineActor);

		GetAllConnectedSplineActors(SplineActorsToVisualize);

		for (auto SplineActor : SplineActorsToVisualize)
		{
			if (SplineActor == nullptr)
				continue;

			VisualizeSpline(SplineActor.ProjectedHeightSplineComponent, -1.f, FLinearColor::LucBlue, 20.f);
			VisualizeSpline(SplineActor.ProjectedHeightSplineComponent, 0.f, FLinearColor::Green, 10.f);
			VisualizeSpline(SplineActor.ProjectedHeightSplineComponent, 1.f, FLinearColor::LucBlue, 20.f);
		}		
	}

	void GetAllConnectedSplineActors(TArray<AProjectedHeightSplineActor> SplineActors)
	{
		for (auto SplineActor : SplineActors)
		{
			if (SplineActor == nullptr)
				continue;

			TArray<AProjectedHeightSplineActor> SplineActorsToAdd;
			TArray<FSplineConnection> SplineConnections;
			SplineConnections.Append(SplineActor.InSplines);
			SplineConnections.Append(SplineActor.OutSplines);

			for (auto SplineConnection : SplineConnections)
			{
				if (!SplineActorsToVisualize.Contains(SplineConnection.SplineActor))
					SplineActorsToAdd.AddUnique(SplineConnection.SplineActor);
			}

			if (SplineActorsToAdd.Num() > 0)
			{
				SplineActorsToVisualize.Append(SplineActorsToAdd);	
				GetAllConnectedSplineActors(SplineActorsToAdd);
			}
		}

		return;
	}

	void VisualizeSpline(UProjectedHeightSplineComponent Spline, float Offset = 0.f, FLinearColor Color = FLinearColor::Green, float Thickness = 10.f)
	{
		int NumOfPoints;
		float PointDistance = 250.f;
		TArray<FVector> Points;

		NumOfPoints = Spline.SplineLength / PointDistance;

		if (NumOfPoints > 0)
			PointDistance = Spline.SplineLength / NumOfPoints;

		for (int i = 0; i <= NumOfPoints; i++)
		{
			float PointDistanceOnSpline = i * PointDistance;

			FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(PointDistanceOnSpline, ESplineCoordinateSpace::World, true);

			FVector Point = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * TransformAtDistance.Scale3D.Y * Spline.BaseWidth * Offset);

			Points.Add(Point);
		}

		for (int i = 0; i < Points.Num() - 1; i++)
		{
			FVector NextPoint;

			if (Points.IsValidIndex(i + 1))
				NextPoint = Points[i + 1];
			else
				NextPoint = Points[0];

			DrawLine(Points[i], NextPoint, Color, Thickness, false);
		}

	}

}

class UConnectedSplineVisualizerComponent : UActorComponent
{
}

struct FSplineConnection
{
	UPROPERTY()
	AProjectedHeightSplineActor SplineActor;	

	UPROPERTY()
	float Weight = 1.f;
}

class AProjectedHeightSplineActor : AHazeSplineActor
{
	UPROPERTY(DefaultComponent)
	UConnectedSplineVisualizerComponent VisualizerComponent;

    UPROPERTY(DefaultComponent, RootComponent)
    UProjectedHeightSplineComponent ProjectedHeightSplineComponent;

	UPROPERTY(Category = "Connection Settings")
	TArray<FSplineConnection> InSplines;

	UPROPERTY(Category = "Connection Settings")
	TArray<FSplineConnection> OutSplines;

    UPROPERTY(DefaultComponent, NotEditable, Attach = ProjectedHeightSplineComponent)
    UBillboardComponent BillboardComponent;
	default BillboardComponent.SetRelativeScale3D(4.f);
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline.T_Loft_Spline");

	UFUNCTION(CallInEditor)
	void BakeSplineData()
	{
		ProjectedHeightSplineComponent.BakeHeightData();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UpdateConnections();
	}

	void UpdateConnections()
	{
		for (auto InSpline : InSplines)
		{
			if (InSpline.SplineActor == nullptr || IsConnectedTo(InSpline.SplineActor))
			{
				Log("InSpline Already Connected");
				continue;
			}
			
			FSplineConnection NewConnection;
			NewConnection.SplineActor = this;

			InSpline.SplineActor.OutSplines.AddUnique(NewConnection);
			Log("Added OutPut: ");
		}

		for (auto OutSpline : OutSplines)
		{
		//	if (OutSpline.SplineActor == nullptr || OutSpline.SplineActor.IsConnectedTo(this))
			if (OutSpline.SplineActor == nullptr || IsConnectedTo(OutSpline.SplineActor))
			{
				Log("OutSpline Already Connected");
				continue;
			}

			FSplineConnection NewConnection;
			NewConnection.SplineActor = this;

			OutSpline.SplineActor.InSplines.AddUnique(NewConnection);
		}

		AlignConnections(InSplines, true);
		AlignConnections(OutSplines, false);
	}

	bool IsConnectedTo(AProjectedHeightSplineActor TargetSplineActor)
	{
		TArray<AProjectedHeightSplineActor> SplineActors;

		for (auto InSpline : TargetSplineActor.InSplines)
		{
			SplineActors.Add(InSpline.SplineActor);
		}

		for (auto OutSpline : TargetSplineActor.OutSplines)
		{
			SplineActors.Add(OutSpline.SplineActor);
		}

		Log("IsConnected: " + SplineActors.Contains(this));

		for (auto SplineActor : SplineActors)
		{
			Log("Connected Spline: " + SplineActor.Name);
		}

		return SplineActors.Contains(this);
	}

	void AlignConnections(TArray<FSplineConnection> Connections, bool bInConnections = false)
	{

		if (Connections.Num() == 1)
		{
			FSplineConnection Connection = Connections[0];

			if (bInConnections)
			{
				if (Connection.SplineActor.OutSplines.Num() > 2)
					Connection.SplineActor.AlignConnections(Connection.SplineActor.OutSplines, false);
			}
			else
			{
				if (Connection.SplineActor.InSplines.Num() > 2)
					Connection.SplineActor.AlignConnections(Connection.SplineActor.InSplines, true);
			}

			return;
		}


		// Get WeigthSum
		float WeightSum = 0;
		for (auto Connection : Connections)
		{
			WeightSum += Connection.Weight;
		}

		float Offset = 0.f;

		Log("Aligned Spline Point!");

		for (auto Connection : Connections)
		{
			float WeightScale = Connection.Weight / WeightSum;

			UProjectedHeightSplineComponent Spline = Connection.SplineActor.ProjectedHeightSplineComponent;
			
			int PointIndex = 0;
			int TargetPointIndex = 0;

			if (bInConnections)
			{
				TargetPointIndex = Connection.SplineActor.ProjectedHeightSplineComponent.LastSplinePointIndex;
			}
			else
			{
				PointIndex = ProjectedHeightSplineComponent.LastSplinePointIndex;
			}			

			FTransform PointTransform = ProjectedHeightSplineComponent.GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);
			FVector PointTangent = ProjectedHeightSplineComponent.GetTangentAtSplinePoint(PointIndex, ESplineCoordinateSpace::World);; 
			
			float Span = PointTransform.Scale3D.Y * Spline.BaseWidth * WeightScale * 2.f;

			FVector PointLocation = PointTransform.Location - (PointTransform.Rotation.RightVector * PointTransform.Scale3D.Y * ProjectedHeightSplineComponent.BaseWidth) + (PointTransform.Rotation.RightVector * (Offset + Span / 2.f));

			Offset += Span;

			Connection.SplineActor.ProjectedHeightSplineComponent.SetLocationAtSplinePoint(TargetPointIndex, PointLocation, ESplineCoordinateSpace::World);	
			
			// Rotation?
			Connection.SplineActor.ProjectedHeightSplineComponent.SetRotationAtSplinePoint(TargetPointIndex, PointTransform.Rotator(), ESplineCoordinateSpace::World);	

			Connection.SplineActor.ProjectedHeightSplineComponent.SetTangentAtSplinePoint(TargetPointIndex, PointTangent, ESplineCoordinateSpace::World);
			Connection.SplineActor.ProjectedHeightSplineComponent.SetScaleAtSplinePoint(TargetPointIndex, FVector(1.f, PointTransform.Scale3D.Y * WeightScale, 1.f));
		}
	}

	void AlignSplinePoints()
	{
	}

	AProjectedHeightSplineActor GetNextSplineActor(float &Offset, bool bForward = true)
	{
		TArray<FSplineConnection> SplineConnections = bForward ? OutSplines : InSplines;

		if (SplineConnections.Num() == 0)
			return nullptr;

		if (SplineConnections.Num() > 1)
		{
			return GetSplitSpline(Offset, SplineConnections, bForward);
		}
		else
		{
			return GetMergeSpline(Offset, SplineConnections, bForward);
		}
	}

	AProjectedHeightSplineActor GetSplitSpline(float &Offset, TArray<FSplineConnection> SplineConnections, bool bForward = true)
	{
		TArray<FSplineConnection> Connections = SplineConnections;

		int PointIndex = bForward ? ProjectedHeightSplineComponent.LastSplinePointIndex : 0;

		FTransform PointTransform = ProjectedHeightSplineComponent.GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);

		float SplineWidth = PointTransform.Scale3D.Y * ProjectedHeightSplineComponent.BaseWidth;

		float NormalizedOffset = FMath::Clamp(Offset / SplineWidth, -1.f, 1.f);

		// Get WeigthSum
		float WeightSum = 0.f;

		for (auto Connection : Connections)
		{
			WeightSum += Connection.Weight;
		}

		// Gate Start
		float GateStart = -1.f;

		for (int i = 0; i < Connections.Num(); i++)
		{	
			float GateWidth = (Connections[i].Weight / WeightSum) * 2.f;
			float GateEnd = GateStart + GateWidth;

			if (NormalizedOffset >= GateStart && NormalizedOffset <= GateEnd)
			{
			//	Print("NormalizedOffset: " + NormalizedOffset, 4.f);

				Offset = FMath::GetMappedRangeValueClamped(FVector2D(GateStart, GateEnd), FVector2D(-1.f, 1.f), NormalizedOffset);

			//	Print("WeightSum: " + WeightSum + " GateStart: " + GateStart + " GateWidth" + GateWidth + " GateEnd: " + GateEnd + " NewOffset: " + Offset, 8.f);

				int NewPointIndex = bForward ? 0 : Connections[i].SplineActor.ProjectedHeightSplineComponent.LastSplinePointIndex;

				FTransform NewPointTransform = Connections[i].SplineActor.ProjectedHeightSplineComponent.GetTransformAtSplinePoint(NewPointIndex, ESplineCoordinateSpace::World, true);

				Offset *= NewPointTransform.Scale3D.Y * ProjectedHeightSplineComponent.BaseWidth;				
				
				return Connections[i].SplineActor;
			}

			GateStart += GateWidth;
		}

		return nullptr;
	}

	AProjectedHeightSplineActor GetMergeSpline(float &Offset, TArray<FSplineConnection> SplineConnections, bool bForward = true)
	{
		AProjectedHeightSplineActor MergeSplineActor = SplineConnections[0].SplineActor;

		// Out or In depending on direction !!!!!!! fix
	//	TArray<FSplineConnection> Connections = MergeSplineActor.InSplines;
		TArray<FSplineConnection> Connections = bForward ? MergeSplineActor.InSplines : MergeSplineActor.OutSplines;
	
		// Find Gate
		int GateIndex = 0;
		for (int i = 0; i < Connections.Num(); i++)
		{
			if (Connections[i].SplineActor == this)
			{
				GateIndex = i;
				break;
			}
		}

		int PointIndex = bForward ? ProjectedHeightSplineComponent.LastSplinePointIndex : 0;
		FTransform PointTransform = ProjectedHeightSplineComponent.GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);

		float SplineWidth = PointTransform.Scale3D.Y * ProjectedHeightSplineComponent.BaseWidth;

		float NormalizedOffset = FMath::Clamp(Offset / SplineWidth, -1.f, 1.f);

		// Get WeigthSum
		float WeightSum = 0.f;

		for (auto Connection : Connections)
		{
			WeightSum += Connection.Weight;
		}

		// Gate Start
		float GateStart = -1.f;

		for (int i = 0; i < Connections.Num(); i++)
		{	
			float GateWidth = (Connections[i].Weight / WeightSum) * 2.f;
			float GateEnd = GateStart + GateWidth;

			if (i == GateIndex)
			{
				Offset = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(GateStart, GateEnd), NormalizedOffset);

				int NewPointIndex = bForward ? 0 : MergeSplineActor.ProjectedHeightSplineComponent.LastSplinePointIndex;
				FTransform NewPointTransform = MergeSplineActor.ProjectedHeightSplineComponent.GetTransformAtSplinePoint(NewPointIndex, ESplineCoordinateSpace::World, true);

				Offset *= NewPointTransform.Scale3D.Y * ProjectedHeightSplineComponent.BaseWidth;				
				
				return MergeSplineActor;
			}

			GateStart += GateWidth;
		}

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

/*
#if EDITOR
    default ProjectedHeightSplineComponent.bShouldVisualizeScale = true;
    default ProjectedHeightSplineComponent.ScaleVisualizationWidth = 100.f;
#endif
*/
}