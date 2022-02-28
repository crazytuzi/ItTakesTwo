import Peanuts.Spline.SplineComponent;

class AHorseDerbyScrollingBackgroundActor : AHazeActor
{
	//Background Actor = Each background piece.
	//BackgroundSplineActor = Manager per background layer, owner of spline and array of pieces.

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComp;

	UHazeSplineComponent ActiveSpline;
	EHazeUpdateSplineStatusType SplineStatus;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
	}

	void SetupObject(UHazeSplineComponent SplineComp)
	{
		SplineFollowComp.ActivateSplineMovement(SplineComp);
		ActiveSpline = SplineComp;

		FHazeSplineSystemPosition SystemPosition;
		SplineFollowComp.UpdateSplineMovement(ActorLocation, SystemPosition);
	}

	void SetAtSplineEnd()
	{
		FVector EndLocation = ActiveSpline.GetLocationAtDistanceAlongSpline(ActiveSpline.GetSplineLength(), ESplineCoordinateSpace::World);

		FHazeSplineSystemPosition SystemPosition;
		SplineFollowComp.UpdateSplineMovement(EndLocation, SystemPosition);
		SetActorLocation(SystemPosition.WorldLocation);
	}

	void ActivateAtWorldLocation(FVector NewWorldLocation)
	{
		FHazeSplineSystemPosition SystemPosition;
		SplineFollowComp.UpdateSplineMovement(NewWorldLocation, SystemPosition);
		SetActorLocation(SystemPosition.WorldLocation);
	}

}