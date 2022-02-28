import Peanuts.Spline.SplineComponent;
import Vino.Movement.Capabilities.Sliding.SplineSlopeSlidingSettings;


class USlopeSlidingSplineComponent : UHazeSplineComponent
{

	// Actor where sliding spline will try and find other spline to copy. Default to self it cant find any.
	UPROPERTY(Category = "Spline Slope Sliding")
	AActor SplineActorToCopy;

	FSplineSlopeSlidingSettings SlidingSettings;

	UHazeSplineComponent FindSplineComponentToCopy()
	{
		if (SplineActorToCopy == nullptr)		
			SplineActorToCopy = Owner;

		if (!ensure(SplineActorToCopy != nullptr))
			return nullptr;

		UHazeSplineComponent Output = nullptr;
		TArray<UActorComponent> SplineComponents = SplineActorToCopy.GetComponentsByClass(UHazeSplineComponent::StaticClass());
		for (UActorComponent Comp : SplineComponents)
		{
			if (Comp == this)
				continue;
			
			Output = Cast<UHazeSplineComponent>(Comp);
			break;
		}

		return Output;
	}

	float GetClampStartingDistanceAtSplineDistance(float DistanceOnSpline) const
	{
		return GetScaleAtDistanceAlongSpline(DistanceOnSpline).Y * SlidingSettings.StartClampingSideSpeedDistance;
	}

	float GetMaxSideDistanceAtSplineDistance(float DistanceOnSpline) const
	{
		return GetScaleAtDistanceAlongSpline(DistanceOnSpline).Y * SlidingSettings.MaxDistanceAllowedFromSpline;
	}

	// This copies all the points of another spline. Excluding scale.
	// If they have the same amount of points then preserve the scale already set on the current points.	
	void CopyOtherSpline(UHazeSplineComponent SplineToCopy)
	{
		if (!devEnsureAlways(SplineToCopy != nullptr, "Could not find a spline to copy"))
			return;

		AutoTangents = SplineToCopy.AutoTangents;

		if (NumberOfSplinePoints != SplineToCopy.NumberOfSplinePoints)
		{
			ClearCurrentPointsAndLoadNew(SplineToCopy);
		}
		else
		{
			CopySplinePointData(SplineToCopy);
		}

		UpdateSpline();
	}

	void CopySplinePointData(UHazeSplineComponent SplineToCopy)
	{
		const ESplineCoordinateSpace LocalSpace = ESplineCoordinateSpace::Local;

		for (int iPoint = 0; iPoint < NumberOfSplinePoints; ++iPoint)
		{
			SetTangentsAtSplinePoint(iPoint, SplineToCopy.GetArriveTangentAtSplinePoint(iPoint, LocalSpace),
			SplineToCopy.GetLeaveTangentAtSplinePoint(iPoint, LocalSpace), LocalSpace, false);
			SetLocationAtSplinePoint(iPoint, SplineToCopy.GetLocationAtSplinePoint(iPoint, LocalSpace), LocalSpace, false);
			SetRotationAtSplinePoint(iPoint, SplineToCopy.GetRotationAtSplinePoint(iPoint, LocalSpace), LocalSpace, false);
			SetSplinePointType(iPoint, SplineToCopy.GetSplinePointType(iPoint), false);
		}
	}

	void ClearCurrentPointsAndLoadNew(UHazeSplineComponent SplineToCopy)
	{
		ClearSplinePoints();

		for (int iPoint = 0; iPoint < SplineToCopy.NumberOfSplinePoints; ++iPoint)
		{
			FTransform NewPointTransform = SplineToCopy.GetTransformAtSplinePoint(iPoint, ESplineCoordinateSpace::Local);
			FSplinePoint NewSplinePoint = FSplinePoint();
			NewSplinePoint.ArriveTangent = SplineToCopy.GetArriveTangentAtSplinePoint(iPoint, ESplineCoordinateSpace::Local);
			NewSplinePoint.LeaveTangent = SplineToCopy.GetLeaveTangentAtSplinePoint(iPoint, ESplineCoordinateSpace::Local);
			NewSplinePoint.Position = NewPointTransform.Location;
			NewSplinePoint.Rotation = NewPointTransform.Rotation.Rotator();
			NewSplinePoint.InputKey = iPoint;
			NewSplinePoint.Type = ESplinePointType::CurveCustomTangent;
			NewSplinePoint.Scale = SplineToCopy.GetScaleAtSplinePoint(iPoint);
			AddPoint(NewSplinePoint, false);
		}
	}
}