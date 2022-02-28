import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class APirateOceanStreamActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeSplineComponent Spline;

	UPROPERTY()
	float StreamForce = 1500.f;

	UPROPERTY()
	float AllowedDistanceFromSpline = 5000.f;

	UPROPERTY(EditInstanceOnly)
	TArray<APirateOceanStreamActor> LinkedStreams;
}