import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class ARailSpeakerSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;

#if EDITOR
	default SplineComp.bShouldVisualizeScale = true;
#endif
	
	UPROPERTY()
	AActor LastPointAttachment;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (LastPointAttachment != nullptr)
		{
			SplineComp.SetLocationAtSplinePoint(SplineComp.GetLastSplinePointIndex(), LastPointAttachment.ActorLocation, ESplineCoordinateSpace::World);
			SplineComp.SetTangentsAtSplinePoint(SplineComp.GetLastSplinePointIndex(), LastPointAttachment.ActorForwardVector * 1000.f, LastPointAttachment.ActorForwardVector * -1000, ESplineCoordinateSpace::World);
		}
	}
}