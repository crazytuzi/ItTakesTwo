
import Vino.Pierceables.PierceBaseComponent;

/* 
 * Objects that can be pierced will need this component in order to 
 * perform a handshake with the corresponding PiercingComponent in order
 * for the piercing to take place
 * 
 * Actors with PierceableComponent on them will not always become 
 * The parent in the attachment process. PiercingComponent will 
 * decide that and inform everyone involved via the Event delegates
 */

event void FNonPiercingHit(FHitResult HitData, AHazeActor Nail);

event void FConsecutivelyUnpiercedEventSignature(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent ComponentBeingPierced);

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Collision AssetUserData Tags Activation")
class UPierceableComponent : UPierceBaseComponent
{
	UPROPERTY(Category = "Piercing", meta = (BPCannotCallEvent))
	FPiercedEventSignature ConsecutivelyPierced;

	UPROPERTY(Category = "Piercing", meta = (BPCannotCallEvent))
	FConsecutivelyUnpiercedEventSignature ConsecutivelyUnpierced;

	UPROPERTY(Category = "Piercing", meta = (BPCannotCallEvent))
	FNonPiercingHit NonPiercingHit;

	/* Unit: cm. Mesh root will be attached at Impact point. 
		This value will make it penetrate even further in from the root. */
	UPROPERTY()
	float ExtraPiercingDepth = 0.f;		// default should stay at 0. we add permanent piercing depth in piercingComponent

	/* whether pierced nails should block other nails that try to pierce the same location */
	UPROPERTY()
	bool bEnableCollisionForPiercedNails = true;

	UFUNCTION(BlueprintPure)
	bool IsPiercedBy(AActor Piercer) const	
	{
		if(PierceActors.Num() <= 0)
			return false;
		
		return PierceActors.Contains(Piercer);
	}

	void PushPiercingEvent(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent CompBeingPiercead, FHitResult HitResult)
	{
		if(PierceActors.Num() == 0)
			Pierced.Broadcast(ActorDoingThePiercing, ActorBeingPierced, CompBeingPiercead, HitResult);
		ConsecutivelyPierced.Broadcast(ActorDoingThePiercing, ActorBeingPierced, CompBeingPiercead, HitResult);
		PierceActors.AddUnique(ActorDoingThePiercing);
	}

	void PushUnpiercingEvent(AActor OtherActor = nullptr)
	{
		int IndexToRemove = PierceActors.FindIndex(OtherActor);
		if (IndexToRemove == -1)
			return;

		if(PierceActors.Num() <= 1)
			Unpierced.Broadcast();

		AActor ActorDoingThePiercing = OtherActor;
		AActor ActorBeingPierced = GetOwner();
		UPrimitiveComponent ComponentBeingPierced = Cast<UPrimitiveComponent>(OtherActor.GetRootComponent().GetAttachParent());
		ConsecutivelyUnpierced.Broadcast(ActorDoingThePiercing, ActorBeingPierced, ComponentBeingPierced);

		PierceActors.RemoveAtSwap(IndexToRemove);
	}
}
