import Vino.Collision.LazyPlayerOverlapManagerComponent;

class UAutoScaleSplineBoxComponent : UHazeLazyPlayerOverlapComponent
{
	UPROPERTY(NotEditable)
	USplineComponent Spline;

	FVector Lowest;
	FVector Highest;

	UPROPERTY()
	float IterationDistance = 50.f;
	UPROPERTY()
	FVector BoxMargin = FVector(200.f);

	UFUNCTION(BlueprintOverride)	
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)	
	void ConstructionScript()
	{
		Spline = USplineComponent::Get(Owner);

		UpdateBoxLocation();	
		UpdateBoxExtents();
	}

	void UpdateBoxLocation()
	{
		if (Spline == nullptr)
			return;
		
		Lowest = FVector();
		Highest = FVector();
		
		int Iterations = FMath::FloorToInt(Spline.GetSplineLength() / IterationDistance);
		
		for (int Index = 0, Count = Iterations; Index < Count; ++Index)
		{
			FVector SplineLocation = Spline.GetLocationAtDistanceAlongSpline(Index * IterationDistance, ESplineCoordinateSpace::Local);

			if (SplineLocation.X < Lowest.X)
				Lowest.X = SplineLocation.X;
			if (SplineLocation.Y < Lowest.Y)
				Lowest.Y = SplineLocation.Y;
			if (SplineLocation.Z < Lowest.Z)
				Lowest.Z = SplineLocation.Z;

			if (SplineLocation.X > Highest.X)
				Highest.X = SplineLocation.X;
			if (SplineLocation.Y > Highest.Y)
				Highest.Y = SplineLocation.Y;
			if (SplineLocation.Z > Highest.Z)
				Highest.Z = SplineLocation.Z;
		}

		FVector NewLocation = (Lowest + Highest) * 0.5f;
		SetRelativeLocation(NewLocation);
	}

	void UpdateBoxExtents()
	{
		if (Spline == nullptr)
			return;

		FVector Extent;
		Extent.X = ((FMath::Abs(Lowest.X) + Highest.X) * 0.5f) + BoxMargin.X;
		Extent.Y = ((FMath::Abs(Lowest.Y) + Highest.Y) * 0.5f) + BoxMargin.Y;
		Extent.Z = ((FMath::Abs(Lowest.Z) + Highest.Z) * 0.5f) + BoxMargin.Z;

		//SetBoxExtent(Extent, false);
		Shape.Type = EHazeShapeType::Box;
		Shape.BoxExtends = Extent;
	}
}