import Peanuts.Spline.SplineComponent;

class UConnectedHeightSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UConnectedHeightSplineVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ConnectedHeightSplineVisualizerComponent = Cast<UConnectedHeightSplineVisualizerComponent>(Component);
		if (ConnectedHeightSplineVisualizerComponent == nullptr)
			return;

		UConnectedHeightSplineComponent ConnectedHeightSplineComponent = UConnectedHeightSplineComponent::Get(Component.Owner);

		TArray<UConnectedHeightSplineComponent> SplinesToVisualize = ConnectedHeightSplineComponent.GetAllConnectedSplines();

		for (auto Spline : SplinesToVisualize)
		{
			if (Spline == nullptr)
				continue;

			UConnectedHeightSplineComponent DebugSettingsSplineComp = ConnectedHeightSplineComponent.bUseSelectedSettingsForAllConnections ? ConnectedHeightSplineComponent : Spline;

			FLinearColor CenterColor = DebugSettingsSplineComp.CenterLineColor;
			float CenterThickness = DebugSettingsSplineComp.CenterLineThickness;
			FLinearColor WidthColor = DebugSettingsSplineComp.WidthLineColor;
			float WidthThickness = DebugSettingsSplineComp.WidthLineThickness;
			bool bShowProjectionCopy = DebugSettingsSplineComp.bShowProjectionCopy;
			float ProjectionCopyHeight = DebugSettingsSplineComp.ProjectionCopyHeight;
			FLinearColor ProjectionCopyColor = DebugSettingsSplineComp.ProjectionCopyLineColor;
			float ProjectionCopyThickness = DebugSettingsSplineComp.ProjectionCopyThickness;
			FLinearColor HeightColor = DebugSettingsSplineComp.HeightPointColor;
			float HeightSize = DebugSettingsSplineComp.HeightPointSize;

			if (!Spline.bIsGap)
			{

			//	VisualizeSpline(Spline, -1.f, 0.f, FLinearColor::LucBlue, 30.f);
				VisualizeSpline(Spline, 0.f, 0.f, CenterColor, CenterThickness);
			//	VisualizeSpline(Spline, 1.f, 0.f, FLinearColor::LucBlue, 30.f);				
			}
			else
			{
				for (int i = 0; i < 21; i++)
				{
					VisualizeSpline(Spline, FMath::GetMappedRangeValueClamped(FVector2D(0.f, 20.f), FVector2D(-1.f, 1.f), i), Spline.GapZLevel, FLinearColor::Red, 40.f);
				}
			}
			
			VisualizeSpline(Spline, -1.f, 0.f, WidthColor, WidthThickness);
			VisualizeSpline(Spline, 1.f, 0.f, WidthColor, WidthThickness);

			if (bShowProjectionCopy)
			{
				VisualizeSpline(Spline, -1.f, ProjectionCopyHeight, ProjectionCopyColor, ProjectionCopyThickness);
				VisualizeSpline(Spline, 0.f, ProjectionCopyHeight, ProjectionCopyColor, ProjectionCopyThickness);
				VisualizeSpline(Spline, 1.f, ProjectionCopyHeight, ProjectionCopyColor, ProjectionCopyThickness);
			}

			if (Spline.bVisualizeHeight && !Spline.bIsGap)
				VisualizeHeight(Spline, HeightColor, HeightSize);
		}		
	}

	/* Visualize Height */
	void VisualizeHeight(UConnectedHeightSplineComponent Spline, FLinearColor DebugColor, float DebugHeight)
	{
		for (int i = 0; i < Spline.HeightData.Num(); i++)
		{
			float Distance = (i / Spline.YSize) * Spline.XDistance;
			float Offset = (i % Spline.YSize);
			Offset /= Spline.YSize - 1;

			Offset = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(-1.f, 1.f), Offset);

			FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, true);
	
			FVector ProjectionUpVector = Spline.bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;

			FVector LocationData = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Offset * Spline.BaseWidth * TransformAtDistance.Scale3D.Y) + (ProjectionUpVector * Spline.HeightData[i]);

			FLinearColor Color = DebugColor;
			if (Spline.HeightData[i] <= -Spline.ProjectionStartHeight)
				Color = FLinearColor::Red;
			
			DrawPoint(LocationData, Color, DebugHeight);
		}

		/*

		FTransform TransformAtDistance = Spline.GetTransformAtDistanceAlongSpline(Spline.PreviewDistance, ESplineCoordinateSpace::World, true);
		FVector ProjectionUpVector = Spline.bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;
	
		FVector PreviewPoint = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Spline.PreviewOffset * Spline.BaseWidth * TransformAtDistance.Scale3D.Y) + (ProjectionUpVector * Spline.GetZAtDistanceAndOffset(Spline.PreviewDistance, Spline.PreviewOffset));
		DrawPoint(PreviewPoint, FLinearColor::Red, 40.f);
		
		// PreviewFootPrint
		float PreviewZValue = 0.f;
		FVector PreviewNormal;
		Spline.GetNormalAndZFromFootPrintAtDistanceAndOffset(Spline.PreviewDistance, Spline.PreviewOffset, PreviewZValue, PreviewNormal, 10.f, 8);

		FVector PreviewFootPrint = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Spline.PreviewOffset * Spline.BaseWidth * TransformAtDistance.Scale3D.Y) + (TransformAtDistance.Rotation.UpVector * PreviewZValue);

		DrawLine(PreviewFootPrint, PreviewFootPrint + (PreviewNormal * 1000.f), FLinearColor::Blue, 20.f, false);
	//	Print("PreviewHeight: " + Spline.GetZAtDistanceAndOffset(Spline.PreviewDistance, Spline.PreviewOffset));
		
		*/
	}

	void VisualizeSpline(UConnectedHeightSplineComponent Spline, float Offset = 0.f, float HeightOffset = 0.f, FLinearColor Color = FLinearColor::Green, float Thickness = 10.f)
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

			FVector Point = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * TransformAtDistance.Scale3D.Y * Spline.BaseWidth * Offset) + (TransformAtDistance.Rotation.UpVector *  HeightOffset);

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

class UConnectedHeightSplineVisualizerComponent : UActorComponent
{
}

struct FConnectedHeightSplineConnection
{
	UPROPERTY()
	AActor SplineActor;

	UPROPERTY()
	UConnectedHeightSplineComponent Spline;

	UPROPERTY()
	float Weight = 1.f;
}

class UConnectedHeightSplineComponent : UHazeSplineComponent
{

#if EDITOR
    default bShouldVisualizeScale = true;
    default ScaleVisualizationWidth = 100.f;
#endif

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings")
	bool bVisualizeHeight = true;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings")
	bool bUseSelectedSettingsForAllConnections = true;


	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Center")
	float CenterLineThickness = 10.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Center")
	FLinearColor CenterLineColor = FLinearColor::Green;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Width")
	float WidthLineThickness = 15.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Width")
	FLinearColor WidthLineColor = FLinearColor::LucBlue;	

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Height")
	float HeightPointSize = 20.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Height")
	FLinearColor HeightPointColor = FLinearColor::Green;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Projection Copy")
	bool bShowProjectionCopy = false;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Projection Copy", Meta = (EditCondition=bShowProjectionCopy, EditConditionHides))
	float ProjectionCopyHeight = 1000.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Projection Copy", Meta = (EditCondition=bShowProjectionCopy, EditConditionHides))
	float ProjectionCopyThickness = 15.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Visualize Settings|Projection Copy", Meta = (EditCondition=bShowProjectionCopy, EditConditionHides))
	FLinearColor ProjectionCopyLineColor = FLinearColor::Yellow;


	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	bool bUseHeightData = true;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	bool bBakeOnConstruction = true;

	UPROPERTY(Category = "ConnectedHeightSpline | Connection Settings")
	TArray<FConnectedHeightSplineConnection> InSplines;

	UPROPERTY(Category = "ConnectedHeightSpline | Connection Settings")
	TArray<FConnectedHeightSplineConnection> OutSplines;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	ETraceTypeQuery TraceChannel = ETraceTypeQuery::Visibility;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	bool bTraceComplex = true;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float ProjectionStartHeight = 1000.f;	

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float ProjectionDistance = 2000.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	TArray<float> HeightData;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float TargetXDistance = 200.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float XDistance;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	int YSize = 9;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	bool bVerticalProjection = false;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float PreviewDistance = 0.f;
	
	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	float PreviewOffset = 0.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Height Bake Settings")
	int PreviewIndex = 0;

	UPROPERTY(Category = "ConnectedHeightSpline | Special Settings")
	UCurveFloat DistanceCurve;

	UPROPERTY(Category = "ConnectedHeightSpline | Special Settings")
	bool bIsGap = false;

	UPROPERTY(Category = "ConnectedHeightSpline | Special Settings")
	bool bGapHasBottom = false;

	UPROPERTY(Category = "ConnectedHeightSpline | Special Settings")
	float GapZLevel = 0.f;

	UPROPERTY(Category = "ConnectedHeightSpline | Special Settings")
	bool bAutoJump = false;

	UPROPERTY(Category = "ConnectedHeightSpline")
	bool bFreezeSpline = false;

	float YDistance;

	int XSize;

	float BaseWidth = 100.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR		
		SetEditorScaleVisualizationWidth(BaseWidth);

		// Set Spline Editor Color
		SetEditorUnselectedSplineSegmentColor(FLinearColor::Green);

		if (bIsGap)
			SetEditorUnselectedSplineSegmentColor(FLinearColor::Red);

#endif

		XSize = SplineLength / TargetXDistance;
		XDistance = SplineLength / XSize;

		// Update Spline Actor References
		for (auto Spline : InSplines)
		{
			if (Spline.SplineActor != nullptr)
			{
				auto ConnectedHeightSplineComponent = UConnectedHeightSplineComponent::Get(Spline.SplineActor);
				Spline.Spline = ConnectedHeightSplineComponent;
			}
		}

		for (auto Spline : OutSplines)
		{
			if (Spline.SplineActor != nullptr)
			{
				auto ConnectedHeightSplineComponent = UConnectedHeightSplineComponent::Get(Spline.SplineActor);
				Spline.Spline = ConnectedHeightSplineComponent;
			}
		}

		// Update shared settings on connected splines
		TArray<UConnectedHeightSplineComponent> ConnectedSplines = GetAllConnectedSplines();
		for (auto Spline : ConnectedSplines)
		{
			Spline.bVisualizeHeight = bVisualizeHeight;
			Spline.bUseHeightData = bUseHeightData;
			Spline.bBakeOnConstruction = bBakeOnConstruction;
			Spline.bFreezeSpline = bFreezeSpline;
		}

		// Only update baking when in non play mode
		/*
		if (bBakeOnConstruction && !World.IsGameWorld())
			BakeHeightData();
		*/

		UpdateConnections();

		UConnectedHeightSplineVisualizerComponent VisualizerComponent = UConnectedHeightSplineVisualizerComponent::Create(Owner);
	}

	/* ********************************
		Height
	**********************************/
	UFUNCTION(CallInEditor, Category = "ConnectedHeightSpline | Height Bake Settings")
	void BakeAllConnectedSplinesHeightData()
	{
		TArray<UConnectedHeightSplineComponent> Splines = GetAllConnectedSplines();

	//	Print("Spline: " + Splines.Num(), 3.f, FLinearColor::Green);

		for (auto Spline : Splines)
		{
			Spline.BakeHeightData();
		}
	}

	UFUNCTION(CallInEditor, Category = "ConnectedHeightSpline | Height Bake Settings")
	void BakeHeightData()
	{
		HeightData.Empty();

		for (int X = 0; X <= XSize; X++)
		{
			for (int Y = 0; Y < YSize; Y++)
			{
				FTransform TransformAtDistance = GetTransformAtDistanceAlongSpline(X * XDistance, ESplineCoordinateSpace::World, true);
				
				// Hmm?
				YDistance = ((BaseWidth * 2.f) / (YSize - 1)) * TransformAtDistance.Scale3D.Y;

				// Set UpVector
				FVector ProjectionUpVector = bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;

				FVector Offset = (TransformAtDistance.Rotation.RightVector * Y * YDistance) - (TransformAtDistance.Rotation.RightVector * BaseWidth * TransformAtDistance.Scale3D.Y);
				FVector Start = TransformAtDistance.Location + Offset + (ProjectionUpVector * ProjectionStartHeight);
				FVector End = Start - ProjectionUpVector * ProjectionDistance;
				TArray<AActor> ActorsToIgnore;
				FHitResult HitResult;

				if (!System::LineTraceSingle(Start, End, TraceChannel, bTraceComplex, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
				{
					Log("Failed Trace Data!");
					HeightData.Add(-ProjectionStartHeight);

					continue;
				}

				HeightData.Add(-HitResult.Distance + ProjectionStartHeight);

			}
		}
	}

	UFUNCTION()
	float GetZAtDistanceAndOffset(float Distance, float Offset)
	{
		float MappedOffset = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(0.f, 1.f), Offset);
		
		float XValue = Distance / XDistance;
		float YValue = MappedOffset / (1.f / (YSize - 1));

		float XWhole = 0.f;
		float XRemainder = FMath::Modf(XValue, XWhole);

		float YWhole = 0.f;
		float YRemainder = FMath::Modf(YValue, YWhole);

		int Index = (XWhole * YSize) + YWhole;

		float Y1Result = FMath::Lerp(GetZAtIndex(Index), GetZAtIndex(Index + 1), YRemainder);
		float Y2Result = FMath::Lerp(GetZAtIndex(Index + YSize), GetZAtIndex(Index + YSize + 1), YRemainder);
		float Result = FMath::Lerp(Y1Result, Y2Result, XRemainder);

		return Result;
	}

	UFUNCTION()
	float GetZAtIndex(int Index)
	{
		int ZIndex = Index;

		if (ZIndex >= HeightData.Num())
			ZIndex -= HeightData.Num();

	//	System::DrawDebugPoint(GetIndexAsWorldLocation(ZIndex), 25.f, FLinearColor::Red);

		return HeightData[ZIndex];
	}

	UFUNCTION()
	FVector GetIndexAsWorldLocation(int Index)
	{
		float Distance = (Index / YSize) * XDistance;
		float Offset = (Index % YSize);
		
		Offset /= YSize - 1;

		Offset = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(-1.f, 1.f), Offset);

		FTransform TransformAtDistance = GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, true);
	
		FVector ProjectionUpVector = bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;

		FVector LocationData = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Offset * BaseWidth * TransformAtDistance.Scale3D.Y) - (ProjectionUpVector * HeightData[Index]);

		return LocationData;
	}

	/* ********************************
		Connections
	**********************************/

	void UpdateConnections()
	{
		for (auto InSpline : InSplines)
		{

			Log("Connected Spline: " + InSpline.Spline.Name);

			if (InSpline.Spline == nullptr || IsConnectedTo(InSpline.Spline))
			{
				Log("InSpline Already Connected");
				continue;
			}
			
			FConnectedHeightSplineConnection NewConnection;
			NewConnection.Spline = this;
			NewConnection.SplineActor = this.Owner; // Add the Actor owning this spline for editor drop tool

			InSpline.Spline.OutSplines.AddUnique(NewConnection);
			Log("Added OutPut: ");
		}

		for (auto OutSpline : OutSplines)
		{
			if (OutSpline.Spline == nullptr || IsConnectedTo(OutSpline.Spline))
			{
				Log("OutSpline Already Connected");
				continue;
			}

			FConnectedHeightSplineConnection NewConnection;
			NewConnection.Spline = this;
			NewConnection.SplineActor = this.Owner; // Add the Actor owning this spline for editor drop tool

			OutSpline.Spline.InSplines.AddUnique(NewConnection);
		}

		AlignConnections(InSplines, true);
		AlignConnections(OutSplines, false);
	}

	bool IsConnectedTo(UConnectedHeightSplineComponent TargetSpline)
	{
		TArray<UConnectedHeightSplineComponent> Splines;

		for (auto InSpline : TargetSpline.InSplines)
		{
			Splines.Add(InSpline.Spline);
		}

		for (auto OutSpline : TargetSpline.OutSplines)
		{
			Splines.Add(OutSpline.Spline);
		}

		return Splines.Contains(this);
	}

	void AlignConnections(TArray<FConnectedHeightSplineConnection> Connections, bool bInConnections = false)
	{

		if (Connections.Num() == 1)
		{
			FConnectedHeightSplineConnection Connection = Connections[0];

			if (bInConnections)
			{
				if (Connection.Spline.OutSplines.Num() > 1) // 2
				{
					Connection.Spline.AlignConnections(Connection.Spline.OutSplines, false);
			
					return;
				}
			}
			else
			{
				if (Connection.Spline.InSplines.Num() > 1) // 2
				{
					Connection.Spline.AlignConnections(Connection.Spline.InSplines, true);
			
					return;
				}
			}

		//	return;
		}

		// Get WeigthSum
		float WeightSum = 0;
		for (auto Connection : Connections)
		{
			WeightSum += Connection.Weight;
		}

		float Offset = 0.f;

	//	Log("Aligned Spline Point!");

		for (auto Connection : Connections)
		{
			float WeightScale = Connection.Weight / WeightSum;

			UConnectedHeightSplineComponent Spline = Connection.Spline;
			
			int PointIndex = 0;
			int TargetPointIndex = 0;

			if (bInConnections)
			{
				TargetPointIndex = Connection.Spline.LastSplinePointIndex;
			}
			else
			{
				PointIndex = LastSplinePointIndex;
			}

			FTransform PointTransform = GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);
			FVector PointTangent = GetTangentAtSplinePoint(PointIndex, ESplineCoordinateSpace::World);
			
			float Span = PointTransform.Scale3D.Y * Spline.BaseWidth * WeightScale * 2.f;

			FVector PointLocation = PointTransform.Location - (PointTransform.Rotation.RightVector * PointTransform.Scale3D.Y * BaseWidth) + (PointTransform.Rotation.RightVector * (Offset + Span / 2.f));

			Offset += Span;

			// Do all this in in Connection Space to make sure rotation and stuff works - not sure why world doesn't
			FVector LocalPointLocation = Connection.Spline.Owner.ActorTransform.InverseTransformPosition(PointLocation);
			FRotator LocalPointRotation = Connection.Spline.Owner.ActorTransform.InverseTransformRotation(PointTransform.Rotation).Rotator();
			FVector LocalPointTangent = Connection.Spline.Owner.ActorTransform.InverseTransformVector(PointTangent);
			
			Connection.Spline.SetLocationAtSplinePoint(TargetPointIndex, LocalPointLocation, ESplineCoordinateSpace::Local);	
			Connection.Spline.SetRotationAtSplinePoint(TargetPointIndex, LocalPointRotation, ESplineCoordinateSpace::Local);	
			Connection.Spline.SetTangentAtSplinePoint(TargetPointIndex, LocalPointTangent, ESplineCoordinateSpace::Local);
			Connection.Spline.SetScaleAtSplinePoint(TargetPointIndex, FVector(1.f, PointTransform.Scale3D.Y * WeightScale, 1.f));
		}
	}

	UConnectedHeightSplineComponent GetNextSpline(float &Offset, bool bForward = true)
	{
		TArray<FConnectedHeightSplineConnection> SplineConnections = bForward ? OutSplines : InSplines;

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

	UConnectedHeightSplineComponent GetSplitSpline(float &Offset, TArray<FConnectedHeightSplineConnection> SplineConnections, bool bForward = true)
	{
		TArray<FConnectedHeightSplineConnection> Connections = SplineConnections;

		int PointIndex = bForward ? LastSplinePointIndex : 0;

		FTransform PointTransform = GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);

		float SplineWidth = PointTransform.Scale3D.Y * BaseWidth;

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
				Offset = FMath::GetMappedRangeValueClamped(FVector2D(GateStart, GateEnd), FVector2D(-1.f, 1.f), NormalizedOffset);

				int NewPointIndex = bForward ? 0 : Connections[i].Spline.LastSplinePointIndex;

				FTransform NewPointTransform = Connections[i].Spline.GetTransformAtSplinePoint(NewPointIndex, ESplineCoordinateSpace::World, true);

				Offset *= NewPointTransform.Scale3D.Y * BaseWidth;				
				
				return Connections[i].Spline;
			}

			GateStart += GateWidth;
		}

		return nullptr;
	}

	UConnectedHeightSplineComponent GetMergeSpline(float &Offset, TArray<FConnectedHeightSplineConnection> SplineConnections, bool bForward = true)
	{
		UConnectedHeightSplineComponent MergeSpline = SplineConnections[0].Spline;

		// Out or In depending on direction !!!!!!! fix
	//	TArray<FSplineConnection> Connections = MergeSplineActor.InSplines;
		TArray<FConnectedHeightSplineConnection> Connections = bForward ? MergeSpline.InSplines : MergeSpline.OutSplines;
	
		// Find Gate
		int GateIndex = 0;
		for (int i = 0; i < Connections.Num(); i++)
		{
			if (Connections[i].Spline == this)
			{
				GateIndex = i;
				break;
			}
		}

		int PointIndex = bForward ? LastSplinePointIndex : 0;
		FTransform PointTransform = GetTransformAtSplinePoint(PointIndex, ESplineCoordinateSpace::World, true);

		float SplineWidth = PointTransform.Scale3D.Y * BaseWidth;

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

				int NewPointIndex = bForward ? 0 : MergeSpline.LastSplinePointIndex;
				FTransform NewPointTransform = MergeSpline.GetTransformAtSplinePoint(NewPointIndex, ESplineCoordinateSpace::World, true);

				Offset *= NewPointTransform.Scale3D.Y * BaseWidth;				
				
				return MergeSpline;
			}

			GateStart += GateWidth;
		}

		return nullptr;
	}

	TArray<UConnectedHeightSplineComponent> GetAllConnectedSplines()
	{
		TArray<UConnectedHeightSplineComponent> Splines;
		Splines.Add(this);
		TArray<UConnectedHeightSplineComponent> SplinesToAdd;
		SplinesToAdd.Add(this);

		while (SplinesToAdd.Num() > 0)
		{
			TArray<UConnectedHeightSplineComponent> SplinesToCheck = SplinesToAdd;
			SplinesToAdd.Empty();

			for (auto Spline : SplinesToCheck)
			{
				if (Spline == nullptr)
					continue;
				
				TArray<FConnectedHeightSplineConnection> SplineConnections;
				SplineConnections.Append(Spline.InSplines);
				SplineConnections.Append(Spline.OutSplines);

				for (auto SplineConnection : SplineConnections)
				{
					if (!Splines.Contains(SplineConnection.Spline))
						SplinesToAdd.AddUnique(SplineConnection.Spline);
				}		
			}

			Splines.Append(SplinesToAdd);
		}
	
		return Splines;
	}


	/* ********************************
		Get Normal And Z At Distance And Offset
	**********************************/

	void GetNormalAndZFromFootPrintAtDistanceAndOffset(float DistanceOnSpline, float Offset, float &OutZ, FVector &OutNormal, float Radius = 100.f, int Samples = 4, float ExtraDistanceOffset = 0.f)
	{
		// If we're doing only one sample we do simplfied result
		if (Samples <= 1)
		{
			FTransform SampleTransform = GetTransformAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World, true);

			float SplineWidth = SampleTransform.Scale3D.Y * BaseWidth;

			// Clamp SampleOffset
			float SampleOffset = FMath::Clamp(Offset, -SplineWidth, SplineWidth);

			// - 0.001f to prevent offset to be 1.0 and sample next row
			float NormalizedOffset = FMath::Clamp(SampleOffset / SplineWidth, -1.f, 1.f - 0.001f);

			OutZ = GetZAtDistanceAndOffset(DistanceOnSpline, NormalizedOffset);
			OutNormal = SampleTransform.Rotation.UpVector;

		//	System::DrawDebugSphere(SampleTransform.Location, 25.f, 12, FLinearColor::Green, 0, 20.f);

			return;
		}

		float AverageZ = 0.f;
		FVector AverageNormal;

		TArray<FVector> LocationSamples;
		TArray<FVector> NormalSamples;
		float AngleStep = TAU / Samples;

		for (int i = 0; i < Samples; i++)
		{
			UConnectedHeightSplineComponent SampleSpline = this;
			float SampleDistance = DistanceOnSpline + FMath::Cos(i * AngleStep) * Radius;
			SampleDistance += ExtraDistanceOffset;
			float SampleOffset = Offset + FMath::Sin(i * AngleStep) * Radius;

			// Get Samples From Next/Previous Spline if needed
			if (SampleDistance > SampleSpline.SplineLength)
			{	
				UConnectedHeightSplineComponent PreviousSampleSpline = SampleSpline;	
			
				SampleDistance -= SampleSpline.SplineLength;

				if (!SampleSpline.IsClosedLoop())
				{
				//	SampleDistance -= SampleSpline.SplineLength;
					SampleSpline = SampleSpline.GetNextSpline(SampleOffset, true);
				}

				// If it is the end of the line
				if (SampleSpline == nullptr || SampleSpline.bIsGap)
				{
					SampleSpline = PreviousSampleSpline;
					SampleDistance = SampleSpline.SplineLength;
				}
					
			}
			else if (SampleDistance < 0)
			{	
				UConnectedHeightSplineComponent PreviousSampleSpline = SampleSpline;

				if (!SampleSpline.IsClosedLoop())
				{
					SampleSpline = SampleSpline.GetNextSpline(SampleOffset, false);
		
					if (SampleSpline != nullptr)
						SampleDistance += SampleSpline.SplineLength;
				}
				else
				{
					SampleDistance += SampleSpline.SplineLength;
				}

				if (SampleSpline == nullptr || SampleSpline.bIsGap)
				{
					SampleSpline = PreviousSampleSpline;
					SampleDistance = 0.f;
				}

			}

			FTransform SampleTransform = SampleSpline.GetTransformAtDistanceAlongSpline(SampleDistance, ESplineCoordinateSpace::World, true);

			float SplineWidth = SampleTransform.Scale3D.Y * SampleSpline.BaseWidth;

			// Clamp SampleOffset
			SampleOffset = FMath::Clamp(SampleOffset, -SplineWidth, SplineWidth);

			// - 0.001f to prevent offset to be 1.0 and sample next row
			float NormalizedOffset = FMath::Clamp(SampleOffset / SplineWidth, -1.f, 1.f - 0.001f);

			float ZOffset = SampleSpline.GetZAtDistanceAndOffset(SampleDistance, NormalizedOffset);
			AverageZ += ZOffset;

			FVector SampleWorldLocation = SampleTransform.Location + (SampleTransform.Rotation.UpVector * ZOffset) + (SampleTransform.Rotation.RightVector * SampleOffset);

			LocationSamples.Add(SampleWorldLocation);
		//	System::DrawDebugSphere(SampleWorldLocation, 25.f, 12, FLinearColor::Green, 0, 20.f);
		//	System::DrawDebugPoint(SampleWorldLocation, 50.f, FLinearColor::Yellow, 0.f);
		}

		for (int i = 0; i < LocationSamples.Num(); i++)
		{					
			FVector SampleNormal = (LocationSamples[Math::IWrap(i + 1, 0, LocationSamples.Num() - 1)] - LocationSamples[i]).CrossProduct((LocationSamples[Math::IWrap(i + 2, 0, LocationSamples.Num() - 1)] - LocationSamples[i]));
			AverageNormal += SampleNormal;
		}

		OutZ = (AverageZ / LocationSamples.Num());
		OutNormal = (AverageNormal / LocationSamples.Num()).GetSafeNormal();

	//	System::DrawDebugLine(OutLocation, OutLocation + OutNormal * 1000.f, FLinearColor::Blue, 0.f, 20.f);
	}

	FTransform GetTransformAtDistanceAndOffset(float Distance, float Offset, bool bNormalizeOffset = false)
	{
		FTransform TransformAtDistance = GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, true);

		float NormalizeOffset = Offset;

		if (bNormalizeOffset)
			NormalizeOffset = FMath::Clamp(Offset / (TransformAtDistance.Scale3D.Y * BaseWidth), -1.f, 1.f - 0.001f);

		FVector Location = TransformAtDistance.Location;
		Location += TransformAtDistance.Rotation.RightVector * NormalizeOffset * BaseWidth * TransformAtDistance.Scale3D.Y;
		Location += TransformAtDistance.Rotation.UpVector * GetZAtDistanceAndOffset(Distance, Offset);

		TransformAtDistance.Location = Location;

		return TransformAtDistance;
	}

}