import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledTunnelEndAlignmentSplineRegion : UHazeSplineRegionComponent
{
	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		if(!EnteringActor.IsA(ABoatsled::StaticClass()))
			return;

		if(!EnteringActor.HasControl())
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(EnteringActor);
		if(Boatsled.CurrentBoatsledder == nullptr)
			return;

		// Leave crumb
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"BoatsledComponent", UBoatsledComponent::Get(Boatsled.CurrentBoatsledder));
		Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnRegionEntered"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnRegionEntered(const FHazeDelegateCrumbData& CrumbData)
	{
		UBoatsledComponent BoatsledComponent = Cast<UBoatsledComponent>(CrumbData.GetObject(n"BoatsledComponent"));
		BoatsledComponent.BoatsledEventHandler.OnBoatsledApproachingTunnelEnd.Broadcast(EndPointLocation);
	}
}