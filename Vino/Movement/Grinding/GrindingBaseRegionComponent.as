import Vino.Movement.Grinding.GrindingReasons;
import Vino.Movement.Grinding.GrindSpline;

UCLASS(Abstract)
class UGrindingBaseRegionComponent : UHazeSplineRegionComponent
{
	// Players have to be grinding in this direction for the region to be able to activate.
	UPROPERTY(Category = "GrindRegion")
	EGrindSplineTravelDirection ActivationDirection = EGrindSplineTravelDirection::Bidirectional;

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
		AGrindspline OwnerGrind = Cast<AGrindspline>(Owner);
		if (OwnerGrind == nullptr)
			return;

		ActivationDirection = OwnerGrind.TravelDirection;
	}

	UFUNCTION(BlueprintOverride)
	bool CanActorEnterRegion(AHazeActor ActiveActor, float CurrentDistance, float PreviousDistance, bool bTravellingForward) const
	{
		if (ActivationDirection == EGrindSplineTravelDirection::Bidirectional)
			return true;

		const EGrindSplineTravelDirection CurrentDirection = bTravellingForward ? EGrindSplineTravelDirection::Forwards : EGrindSplineTravelDirection::Backwards;
		return CurrentDirection == ActivationDirection;
	}
}
