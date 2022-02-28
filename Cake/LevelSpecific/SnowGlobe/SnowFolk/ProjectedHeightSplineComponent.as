import Peanuts.Spline.SplineComponent;

class UProjectedHeightSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UProjectedHeightSplineVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ProjectedHeightSplineVisualizerComponent = Cast<UProjectedHeightSplineVisualizerComponent>(Component);
		if (ProjectedHeightSplineVisualizerComponent == nullptr)
			return;

		TArray<UProjectedHeightSplineComponent> ProjectedHeightSplineComponents;

		Component.Owner.GetComponentsByClass(ProjectedHeightSplineComponents);

		for (UProjectedHeightSplineComponent ProjectedHeightSplineComponent : ProjectedHeightSplineComponents)
		{
	
			for (int i = 0; i < ProjectedHeightSplineComponent.HeightData.Num(); i++)
			{
				float Distance = (i / ProjectedHeightSplineComponent.YSize) * ProjectedHeightSplineComponent.XDistance;
				float Offset = (i % ProjectedHeightSplineComponent.YSize);
				Offset /= ProjectedHeightSplineComponent.YSize - 1;

				Offset = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(-1.f, 1.f), Offset);

				//Offset -= 1.f;

			//	Log("Offset mod: " + Offset);

				FTransform TransformAtDistance = ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, true);
		
				FVector ProjectionUpVector = ProjectedHeightSplineComponent.bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;

				FVector LocationData = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * Offset * ProjectedHeightSplineComponent.BaseWidth * TransformAtDistance.Scale3D.Y) + (ProjectionUpVector * ProjectedHeightSplineComponent.HeightData[i]);

				FLinearColor Color = FLinearColor::Green;

				if (ProjectedHeightSplineComponent.HeightData[i] <= -ProjectedHeightSplineComponent.ProjectionOffset)
					Color = FLinearColor::Red;
				
				DrawPoint(LocationData, Color, 20.f);
			}

			FTransform TransformAtDistance = ProjectedHeightSplineComponent.GetTransformAtDistanceAlongSpline(ProjectedHeightSplineComponent.PreviewDistance, ESplineCoordinateSpace::World, true);
			FVector ProjectionUpVector = ProjectedHeightSplineComponent.bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;
		
			FVector PreviewPoint = TransformAtDistance.Location + (TransformAtDistance.Rotation.RightVector * ProjectedHeightSplineComponent.PreviewOffset * ProjectedHeightSplineComponent.BaseWidth * TransformAtDistance.Scale3D.Y) + (ProjectionUpVector * ProjectedHeightSplineComponent.GetZAtDistanceAndOffset(ProjectedHeightSplineComponent.PreviewDistance, ProjectedHeightSplineComponent.PreviewOffset));
			DrawPoint(PreviewPoint, FLinearColor::Red, 40.f);
			Print("PreviewHeight: " + ProjectedHeightSplineComponent.GetZAtDistanceAndOffset(ProjectedHeightSplineComponent.PreviewDistance, ProjectedHeightSplineComponent.PreviewOffset));
		}
	}

}

class UProjectedHeightSplineVisualizerComponent : UActorComponent
{
}

class UProjectedHeightSplineComponent : UHazeSplineComponent
{

#if EDITOR
    default bShouldVisualizeScale = true;
    default ScaleVisualizationWidth = 100.f;
#endif
	UPROPERTY(Category = "PHS Settings")
	ETraceTypeQuery TraceChannel = ETraceTypeQuery::Visibility;

	UPROPERTY(Category = "PHS Settings")
	bool bTraceComplex = true;

	UPROPERTY(Category = "PHS Settings")
	TArray<float> HeightData;

	UPROPERTY(Category = "PHS Settings")
	float TargetXDistance = 200.f;

	UPROPERTY(Category = "PHS Settings")
	float XDistance;

	UPROPERTY(Category = "PHS Settings")
	int YSize = 9;

	UPROPERTY(Category = "PHS Settings")
	bool bVerticalProjection = false;

	UPROPERTY(Category = "PHS Settings")
	float PreviewDistance = 0.f;
	
	UPROPERTY(Category = "PHS Settings")
	float PreviewOffset = 0.f;

	UPROPERTY(Category = "PHS Settings")
	int PreviewIndex = 0;

	float YDistance;

	int XSize;

	float ProjectionOffset = 1000.f;
	float ProjectionDistance = 2000.f;

	float BaseWidth = 100.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR		
		SetEditorScaleVisualizationWidth(BaseWidth);
#endif

		XSize = SplineLength / TargetXDistance;
		XDistance = SplineLength / XSize;

	//	BakeHeightData();

		UProjectedHeightSplineVisualizerComponent VisualizerComponent = UProjectedHeightSplineVisualizerComponent::Create(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(CallInEditor, Category = "PHS Settings")
	void BakeHeightData()
	{
		HeightData.Empty();

		for (int X = 0; X <= XSize; X++)
		{
			for (int Y = 0; Y < YSize; Y++)
			{
				FTransform TransformAtDistance = GetTransformAtDistanceAlongSpline(X * XDistance, ESplineCoordinateSpace::World, true);
				
				// Hmm?
				YDistance = ((BaseWidth * 2.f) / (YSize - 0)) * TransformAtDistance.Scale3D.Y;

				// Set UpVector
				FVector ProjectionUpVector = bVerticalProjection ? FVector::UpVector : TransformAtDistance.Rotation.UpVector;

				FVector Offset = (TransformAtDistance.Rotation.RightVector * Y * YDistance) - (TransformAtDistance.Rotation.RightVector * BaseWidth * TransformAtDistance.Scale3D.Y);
				FVector Start = TransformAtDistance.Location + Offset + (ProjectionUpVector * ProjectionOffset);
				FVector End = Start - ProjectionUpVector * ProjectionDistance;
				TArray<AActor> ActorsToIgnore;
				FHitResult HitResult;

				if (!System::LineTraceSingle(Start, End, TraceChannel, bTraceComplex, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
				{
					Log("Failed Trace Data!");
					HeightData.Add(-ProjectionOffset);

					continue;
				}

				HeightData.Add(-HitResult.Distance + ProjectionOffset);

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

//		Log("XValue: " + XValue + "YValue: " + YValue);

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

}