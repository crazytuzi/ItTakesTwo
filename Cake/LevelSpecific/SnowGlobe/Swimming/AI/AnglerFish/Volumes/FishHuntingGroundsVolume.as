import Vino.AI.Components.GentlemanFightingComponent;
class AFishHuntingGroundsVolume : ATriggerVolume
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

		if (!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;

		// Make sure we get rid of gentleman comp when nothing wants it anymore
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::GetOrCreate(OtherActor);
		if(GentlemanComp == nullptr)
			return;
		GentlemanComp.AddTag(n"FishPrey"); 
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(OtherActor == nullptr)
			return; 
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(OtherActor);
		if(GentlemanComp == nullptr)
			return;

		GentlemanComp.RemoveTag(n"FishPrey"); 
	}
}