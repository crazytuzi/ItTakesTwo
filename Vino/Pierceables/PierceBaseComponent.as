
/**
* Stuff shared between PierceableComp and PiercingComp
*/

event void FPiercedEventSignature(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent ComponentBeingPierced, FHitResult HitResult);
event void FUnpiercedEventSignature();

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Tags Collision AssetUserData Activation")
class UPierceBaseComponent : UActorComponent
{
	default bAutoActivate = true;

	/* Event that will fire when a piercing has taken place in
	the form of attaching one actor to the other actor */
	UPROPERTY(Category = "Piercing", meta = (BPCannotCallEvent))
	FPiercedEventSignature Pierced;

	/* Event that will fire when actors detach from each other. */
	UPROPERTY(Category = "Piercing", meta = (BPCannotCallEvent))
	FUnpiercedEventSignature Unpierced;

	protected TArray<AActor> PierceActors;

	UFUNCTION(BlueprintPure)
	TArray<AActor> GetPiercedActors() const { return PierceActors; }

	UFUNCTION(BlueprintPure)
	bool IsPierced() const	{ return PierceActors.Num() > 0; }

	void PushPiercingEvent(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent CompBeingPiercead, FHitResult HitResult)
	{
		// override in children
	}

	void PushUnpiercingEvent(AActor OtherActor = nullptr)
	{
		// override in children
	}
}

