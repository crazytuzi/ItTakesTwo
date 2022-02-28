import Peanuts.Spline.SplineComponent;

event void FKeyDestinationSignature();

class AMusicalKeyDestination : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;
	default SplineComp.Mobility = EComponentMobility::Static;
	default SplineComp.AutoTangents = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent EditorMesh;
	default EditorMesh.bIsEditorOnly = true;
	default EditorMesh.CollisionProfileName = n"NoCollision";
	default EditorMesh.Mobility = EComponentMobility::Static;
	default EditorMesh.RelativeRotation = FRotator(0.0f, 90.0f, 0.0f);

	UPROPERTY(Category = Debug)
	bool bAlwaysRenderDestination = false;

	FKeyDestinationSignature OnReachedDestination;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SplineComp.SetLocationAtSplinePoint(0, ActorLocation, ESplineCoordinateSpace::World);
	}

	FVector GetSplineStartLocation() const property
	{
		return SplineComp.GetLocationAtSplinePoint(SplineComp.NumberOfSplinePoints - 1, ESplineCoordinateSpace::World);
	}

	float GetSplineLength() const property
	{
		return SplineComp.SplineLength;
	}

#if EDITOR

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!bAlwaysRenderDestination)
			EditorMesh.SetVisibility(false);
	}

#endif // EDITOR

}
