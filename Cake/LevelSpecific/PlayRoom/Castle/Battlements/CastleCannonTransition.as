import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;

class ACastleCannonTransition : ASplineActor
{
	UPROPERTY()
	FCannonTransition BeginningTransition;

	UPROPERTY()
	FCannonTransition EndTransition;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif	

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if (BeginningTransition.Cannon != nullptr)
		{
			SetActorLocation(BeginningTransition.Cannon.ShooterAttach.WorldLocation);
			Spline.SetLocationAtSplinePoint(0, BeginningTransition.Cannon.ShooterAttach.WorldLocation, ESplineCoordinateSpace::World);
		}

		if (EndTransition.Cannon != nullptr)
		{
			int SplineEndPointIndex = Spline.GetNumberOfSplinePoints() - 1;
			Spline.SetLocationAtSplinePoint(SplineEndPointIndex, EndTransition.Cannon.ShooterAttach.WorldLocation, ESplineCoordinateSpace::World);
		}			
    }

	/*bool IsTransitionAtBeginning(FCannonTransition CannonTransition)
	{
		if ()
	}*/
}

enum ECastleCannonTransitionDirection
{
	Left,
	Right
}

struct FCannonTransition
{
	UPROPERTY()
	ECastleCannonTransitionDirection TransitionDirection;

	UPROPERTY()
	ACastleCannon Cannon;
}

struct FPossibleCannonTransition
{
	UPROPERTY()
	ACastleCannonTransition TransitionActor = nullptr;

	UPROPERTY()
	ECastleCannonTransitionDirection TransitionDirection;

}

