import Peanuts.Spline.SplineComponent;

class ASplineMesh : AHazeActor
{
	UPROPERTY(DefaultComponent)
    UHazeSplineComponent Spline;

    UPROPERTY()
    UStaticMesh Mesh;

    UPROPERTY()
    ESplineMeshAxis SplineMeshAxis;

    UPROPERTY()
    float SectionLength = 100.f;

	UPROPERTY()
	bool bExtendMesh = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if(Mesh == nullptr)
            return;

		if(bExtendMesh)
		{
			for(int i = 0; i < Spline.GetNumberOfSplinePoints(); i++)
			{
				USplineMeshComponent SplineMeshComponent = USplineMeshComponent::Create(this);
				SplineMeshComponent.SetForwardAxis(SplineMeshAxis);
				SplineMeshComponent.StaticMesh = Mesh;
				SplineMeshComponent.SetCollisionProfileName(n"BlockAll");
				SplineMeshComponent.SetStartAndEnd(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local),  Spline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::Local),
												Spline.GetLocationAtSplinePoint(i + 1, ESplineCoordinateSpace::Local), Spline.GetTangentAtSplinePoint(i + 1, ESplineCoordinateSpace::Local));
			}
		}
		else
		{
			int TotalSections = FMath::TruncToInt(Spline.GetSplineLength() / SectionLength);
			for(int i = 0; i < TotalSections; i++)
			{
				USplineMeshComponent SplineMeshComponent = USplineMeshComponent::Create(this);
				SplineMeshComponent.SetForwardAxis(SplineMeshAxis);
				SplineMeshComponent.StaticMesh = Mesh;
				SplineMeshComponent.SetCollisionProfileName(n"BlockAll");

				SplineMeshComponent.SetStartAndEnd(Spline.GetLocationAtDistanceAlongSpline(i * SectionLength, ESplineCoordinateSpace::Local),  Spline.GetTangentAtDistanceAlongSpline(i * SectionLength, ESplineCoordinateSpace::Local).GetClampedToSize(0, SectionLength),
				                                   Spline.GetLocationAtDistanceAlongSpline((i + 1) * SectionLength, ESplineCoordinateSpace::Local), Spline.GetTangentAtDistanceAlongSpline((i + 1) * SectionLength, ESplineCoordinateSpace::Local).GetClampedToSize(0, SectionLength));
			}
		}
    }
}