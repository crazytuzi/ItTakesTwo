import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledState;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledMovementTransitionSplineRegion : UHazeSplineRegionComponent
{
	UPROPERTY()
	EBoatsledState NextBoatsledState;

	// In case we need to switch splines. Null otherwise.
	UPROPERTY()
	AActor BoatsledTrack;

	UPROPERTY(meta = (EditCondition = "NextBoatsledState == EBoatsledState::HalfPipeSledding || NextBoatsledState == EBoatsledState::TunnelSledding"))
	float TrackRadius = 500.f;

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		if(!EnteringActor.IsA(ABoatsled::StaticClass()))
			return;

		if(!EnteringActor.HasControl())
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(EnteringActor);
		if(Boatsled.CurrentBoatsledder == nullptr)
		{
			Warning(Name + " Boatsledder in Boatsled " + Boatsled.Name + " is NULL wat?!");
			return;
		}

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"BoatsledComponent", UBoatsledComponent::Get(Boatsled.CurrentBoatsledder));
		Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnBoatsledEnteredRegion"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnBoatsledEnteredRegion(const FHazeDelegateCrumbData& CrumbData)
	{
		UBoatsledComponent BoatsledComponent = Cast<UBoatsledComponent>(CrumbData.GetObject(n"BoatsledComponent"));

		if(BoatsledTrack != nullptr)
		{
			// Not so nice but practical; whale's spline actor owns three spline components
			FName SplineName = NextBoatsledState == EBoatsledState::WhaleSledding ? n"HazeGuideSpline" : NAME_None;
			BoatsledComponent.SetBoatsledTrack(UHazeSplineComponent::Get(BoatsledTrack, SplineName));

			// Set radius (used by half-pipe and tunnel sledding capabilities)
			BoatsledComponent.TrackRadius = TrackRadius;
		}

		// Set state locally because crumb
		BoatsledComponent.SetStateLocal(NextBoatsledState);

		// Poke other player in case sled is finishing
		if(NextBoatsledState == EBoatsledState::Finish)
			UBoatsledComponent::Get(BoatsledComponent.Boatsled.OtherBoatsled.CurrentBoatsledder).SetStateLocal(NextBoatsledState);
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Green;
	}
}