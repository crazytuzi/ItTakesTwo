import Peanuts.Spline.SplineComponent;

class AMoonBaboonPathSpline : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent, NotEditable, Attach = Spline)
    UBillboardComponent BillboardComponent;
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline.T_Loft_Spline");

#if EDITOR
    default Spline.bShouldVisualizeScale = true;
    default Spline.ScaleVisualizationWidth = 100.f;
#endif

	UPROPERTY()
	AActor Moon;
	
	TArray<AActor> ActorsToIgnore;

	UFUNCTION(CallInEditor)
	void SnapToSurface()
	{
		if (Moon != nullptr)
		{
			for (int Index = 0, Count = Spline.GetNumberOfSplinePoints(); Index < Count; ++ Index)
			{
				FVector CurLoc = Spline.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::World);
				FHitResult Ground;
				System::LineTraceSingle(CurLoc, Moon.ActorLocation, ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::ForDuration, Ground, true, DrawTime = 3.f);
				if (Ground.bBlockingHit)
				{
					Spline.SetLocationAtSplinePoint(Index, Ground.Location, ESplineCoordinateSpace::World, true);
					Spline.SetUpVectorAtSplinePoint(Index, Ground.ImpactNormal, ESplineCoordinateSpace::World, true);
				}
			}
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		/*if (Moon != nullptr)
		{
			for (int Index = 0, Count = Spline.GetNumberOfSplinePoints(); Index < Count; ++ Index)
			{
				FVector CurLoc = Spline.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::World);
				FHitResult Ground;
				System::LineTraceSingle(CurLoc, Moon.ActorLocation, ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::ForDuration, Ground, true, DrawTime = 3.f);
				if (Ground.bBlockingHit)
				{
					Spline.SetLocationAtSplinePoint(Index, Ground.Location, ESplineCoordinateSpace::World, true);
					Spline.SetUpVectorAtSplinePoint(Index, Ground.ImpactNormal, ESplineCoordinateSpace::World, true);
				}
			}
		}*/
	}
}