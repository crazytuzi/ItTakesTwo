import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;
class USplineBoatDoorRegionTwo : UHazeSplineRegionComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanActorEnterRegion(AHazeActor ActiveActor, float CurrentDistance, float PreviousDistance, bool bTravellingForward) const
	{
		ASplineBoatActor BoatActor = Cast<ASplineBoatActor>(ActiveActor);
		return BoatActor != nullptr && BoatActor.HasControl();
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		ASplineBoatActor BoatActor = Cast<ASplineBoatActor>(EnteringActor);
		BoatActor.OpenDoorTwo();
	}
}