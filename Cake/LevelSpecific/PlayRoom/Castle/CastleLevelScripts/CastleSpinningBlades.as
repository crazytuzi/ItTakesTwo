import Peanuts.Spline.SplineComponent;

class ACastleSpinningBlades : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent MovementSpline;

	UPROPERTY(DefaultComponent, Attach = MovementSpline)
	UStaticMeshComponent SpinningBlade;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	

	FVector GetSpinningBladesClosestPointOnSpline()
	{
		FVector ClosestPointOnSpline;
		float DistanceAlongSpline;

		MovementSpline.FindDistanceAlongSplineAtWorldLocation(SpinningBlade.WorldLocation, ClosestPointOnSpline, DistanceAlongSpline);
		return ClosestPointOnSpline;
	}
}