

/**
 * Component that contains the Hammered Event. This Event is tightly associated with the Hammerable Tag. 
 */

// You can't pass through TArrays in delegates - but you can pass through Structs!!!
struct FComponentsBeingHammered
{
	UPROPERTY()
	TArray<UPrimitiveComponent> Hammered;

	FComponentsBeingHammered(const TArray<UPrimitiveComponent>& InComponentsBeingHammered)
	{
		Hammered = InComponentsBeingHammered;
	}
};

 event void FHammeredEventSignature(AActor ActorDoingTheHammering, AActor ActorBeingHammered, FComponentsBeingHammered ComponentsBeing);

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Collision AssetUserData Tags")
class UHammerableComponent : UActorComponent
{
	default bAutoActivate = true;

	/* The hammer weapon will fire this event upon playing the hammering animation 
		- if the trace actually hit something with a hammerableComponent */
 	UPROPERTY(Category = "Hammered", meta = (BPCannotCallEvent))
	FHammeredEventSignature OnHammered;

	UFUNCTION()
	void PushHammeredEvent(AActor ActorDoingTheHammering, AActor ActorBeingHammered, TArray<UPrimitiveComponent> ComponentsBeingHammered)
	{
 		OnHammered.Broadcast(ActorDoingTheHammering, ActorBeingHammered, FComponentsBeingHammered(ComponentsBeingHammered));
	}
}



