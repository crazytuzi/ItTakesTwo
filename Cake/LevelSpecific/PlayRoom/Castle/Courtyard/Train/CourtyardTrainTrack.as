import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineMeshCreation;

class ACourtyardTrainTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;
#if Editor
	default Spline.bShouldVisualizeScale = true;
    default Spline.ScaleVisualizationWidth = 100.f;
#endif

	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent RegionContainer;

	UPROPERTY(NotEditable)
	FSplineMeshRangeContainer SplineMeshContainer;

	UPROPERTY()
	FSplineMeshData SplineMeshData;
	default SplineMeshData.Mesh;
	default SplineMeshData.CollisionProfile = n"BlockAll";
	default SplineMeshData.CollisionType = ECollisionEnabled::QueryAndPhysics;
	default SplineMeshData.bSmoothInterpolate = true;
	default SplineMeshData.Mesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Mechanical/Toy_Track_01_Test.Toy_Track_01_Test");

	FHazeSplineSystemPosition StationPositionStart;
	FHazeSplineSystemPosition StationPositionEnd;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BuildMeshes();
	}

	void BuildMeshes()
	{		
		FSplineMeshBuildData BuildData = MakeSplineMeshBuildData(this, Spline, SplineMeshData);

		if (!BuildData.IsValid())
			return;

		BuildSplineMeshes(BuildData, SplineMeshContainer);
	}
}
