import Cake.LevelSpecific.SnowGlobe.Boatsled.Boatsled;

class UBoatsledWhaleRampUpSplineRegion : UHazeSplineRegionComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanActorEnterRegion(AHazeActor ActiveActor, float CurrentDistance, float PreviousDistance, bool bTravellingForward) const
	{
		return ActiveActor.IsA(ABoatsled::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		if(!EnteringActor.HasControl())
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(EnteringActor);
		if(Boatsled.CurrentBoatsledder == nullptr)
			return;

		// Leave crumb
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Boatsled", Boatsled);
		Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnBoatsledEnteredRegion"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnBoatsledEnteredRegion(const FHazeDelegateCrumbData& CrumbData)
	{
		ABoatsled Boatsled = Cast<ABoatsled>(CrumbData.GetObject(n"Boatsled"));
		Boatsled.BoatsledEventHandler.OnBoatsledWhaleRampUp.Broadcast();
	}
}