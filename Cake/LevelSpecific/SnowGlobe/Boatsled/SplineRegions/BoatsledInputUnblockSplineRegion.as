import Cake.LevelSpecific.SnowGlobe.Boatsled.Boatsled;

class UBoatsledInputUnblockSplineRegion : UHazeSplineRegionComponent
{
	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		if(!EnteringActor.HasControl())
			return;

		if(!EnteringActor.IsA(ABoatsled::StaticClass()))
			return;

		ABoatsled Boatsled = Cast<ABoatsled>(EnteringActor);
		Boatsled.CurrentBoatsledder.SetCapabilityActionState(BoatsledTags::BoatsledInputBlock, EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::LucBlue;
	}
}