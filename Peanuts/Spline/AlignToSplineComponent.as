import Peanuts.Spline.SplineComponent;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UAlignToSplineComponent : UActorComponent
{
	UPROPERTY()
	AHazeActor TargetSplineActor;

	UPROPERTY()
	FVector OffsetFromSpline = FVector::ZeroVector;

	UHazeSplineComponent TargetSplineComp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;

		TargetSplineComp = UHazeSplineComponent::Get(TargetSplineActor);
		if (TargetSplineActor == nullptr)
			return;

		float TargetDistance = TargetSplineComp.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FRotator TargetRotation = TargetSplineComp.GetRotationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);
		FVector TargetLocation = TargetSplineComp.GetLocationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);

		FVector DirectionAtDistance = TargetSplineComp.GetDirectionAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);
		Owner.SetActorRotation(TargetRotation);

		TargetLocation += (Owner.ActorUpVector * OffsetFromSpline.Z);
		TargetLocation += (Owner.ActorRightVector * OffsetFromSpline.Y);

		Owner.SetActorLocation(TargetLocation);
	}
}