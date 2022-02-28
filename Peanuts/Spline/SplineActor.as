import Peanuts.Spline.SplineComponent;

class ASplineActor : AHazeSplineActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UHazeSplineComponent Spline;

    UPROPERTY(DefaultComponent, NotEditable, Attach = SplineComponent)
    UBillboardComponent BillboardComponent;
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline.T_Loft_Spline");

#if EDITOR
    default Spline.bShouldVisualizeScale = true;
    default Spline.ScaleVisualizationWidth = 20.f;
#endif
}