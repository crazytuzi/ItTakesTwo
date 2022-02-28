import Vino.Movement.Capabilities.Sliding.SlopeSlidingSplineComponent;
import Vino.Movement.Capabilities.Sliding.DummySlopeSlidingSplineVisualizerComponent;


struct FSplineSlopePointVisualiserData
{
	FVector Location = FVector::ZeroVector;
	FVector UpVector = FVector::ZeroVector;
	FVector RightVector = FVector::ZeroVector;
	FVector Scale = FVector::OneVector;

	FVector GetOffsetedLocation(float SideOffsetAmount, float UpOffsetAmount) const
	{
		FVector SideOffset = RightVector * SideOffsetAmount * Scale.Y;
		FVector UpOffset = UpVector * UpOffsetAmount;

		return Location + SideOffset + UpOffset;
	}
}

class USlopeSlidingSplineVisualiserComponent : UHazeScriptComponentVisualizer
{	
	default VisualizedClass = UDummySlopeSlidingSplineVisualiserComponent::StaticClass();

	float OffsetDistance = 1500.f;

	FSplineSlopeSlidingSettings SlidingSettings;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UDummySlopeSlidingSplineVisualiserComponent DummySpline = Cast<UDummySlopeSlidingSplineVisualiserComponent>(Component);
        USlopeSlidingSplineComponent SplineComp = DummySpline.SplineToVisualise;
        if (!ensure(SplineComp != nullptr))
            return;

		if (SplineComp.NumberOfSplinePoints < 2)
			return;

		
		int SubStepAmount = 20;
        for (int iPoint = 1; iPoint < SplineComp.NumberOfSplinePoints; ++iPoint)
		{
			int FromIndex = iPoint - 1;

			FSplineSlopePointVisualiserData FromPoint;
			FromPoint.Location = SplineComp.GetLocationAtSplinePoint(FromIndex, ESplineCoordinateSpace::World); 
			FromPoint.UpVector = SplineComp.GetUpVectorAtSplinePoint(FromIndex, ESplineCoordinateSpace::World);
			FromPoint.RightVector = SplineComp.GetRightVectorAtSplinePoint(FromIndex, ESplineCoordinateSpace::World);
			FromPoint.Scale = SplineComp.GetScaleAtSplinePoint(FromIndex);

			// substep between points
			for (int iSubStep = 0; iSubStep <= SubStepAmount; ++iSubStep)
			{
				float KeyValue = float(FromIndex) + float(iSubStep) / float(SubStepAmount);

				FromPoint = DrawSubstep(SplineComp, KeyValue, FromPoint);
			}			
		}
	}

	FSplineSlopePointVisualiserData DrawSubstep(const USlopeSlidingSplineComponent SplineComp, float ToKey, const FSplineSlopePointVisualiserData& PreviousPointData)
	{
		FSplineSlopePointVisualiserData NewPoint;
		NewPoint.Location = SplineComp.GetLocationAtSplineInputKey(ToKey, ESplineCoordinateSpace::World);
		NewPoint.UpVector = SplineComp.GetUpVectorAtSplinePoint(ToKey, ESplineCoordinateSpace::World);
		NewPoint.RightVector = SplineComp.GetRightVectorAtSplineInputKey(ToKey, ESplineCoordinateSpace::World);
		NewPoint.Scale = SplineComp.GetScaleAtSplineInputKey(ToKey);

		// RightLine
		DrawLine(PreviousPointData.GetOffsetedLocation(SlidingSettings.StartClampingSideSpeedDistance, OffsetDistance), NewPoint.GetOffsetedLocation(SlidingSettings.StartClampingSideSpeedDistance, OffsetDistance), FLinearColor::Blue);
		DrawLine(PreviousPointData.GetOffsetedLocation(SlidingSettings.MaxDistanceAllowedFromSpline, OffsetDistance), NewPoint.GetOffsetedLocation(SlidingSettings.MaxDistanceAllowedFromSpline, OffsetDistance), FLinearColor::Yellow);

		// LeftLine
		DrawLine(PreviousPointData.GetOffsetedLocation(-SlidingSettings.StartClampingSideSpeedDistance, OffsetDistance), NewPoint.GetOffsetedLocation(-SlidingSettings.StartClampingSideSpeedDistance, OffsetDistance), FLinearColor::Red);
		DrawLine(PreviousPointData.GetOffsetedLocation(-SlidingSettings.MaxDistanceAllowedFromSpline, OffsetDistance), NewPoint.GetOffsetedLocation(-SlidingSettings.MaxDistanceAllowedFromSpline, OffsetDistance), FLinearColor::Yellow);

		return NewPoint;
	}
}