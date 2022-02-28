import Vino.AI.Components.GentlemanFightingComponent;
class AFishHidingPlaceVolume : ATriggerVolume
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		// When spawning, a player won't trigger any overlap notifies (e.g. if a level containing this volume is streamed in and an activator is standing inside it) 
		// Trigger begin overlap events on any actors we currently overlap
		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors);
		for (AActor Overlap : OverlappingActors)
		{
			if (Overlap != nullptr)
				ActorBeginOverlap(Overlap);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if (OtherActor == nullptr)
			return; 
	
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(OtherActor);
		if(GentlemanComp == nullptr)
			return;
		GentlemanComp.AddTag(n"FishHiding"); 
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(OtherActor == nullptr)
			return; 
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(OtherActor);
		if(GentlemanComp == nullptr)
			return;

		GentlemanComp.RemoveTag(n"FishHiding"); 
	}
}