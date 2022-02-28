import Peanuts.Spline.SplineComponent;
class AMicrophoneChaseRespawnSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;
	default Spline.AutoTangents = true;
#if EDITOR
	default Spline.ScaleVisualizationWidth = 200.f;
	default Spline.bShouldVisualizeScale = true;
	default Spline.SetEditorUnselectedSplineSegmentColor(FLinearColor::Green);
#endif

	UPROPERTY(DefaultComponent, Attach = Spline)
	UHazeSplineRegionContainerComponent SplineRegionContainer;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollow;
 
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
}