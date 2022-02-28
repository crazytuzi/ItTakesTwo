
event void FHitByMatchConsumed(AActor Match, UPrimitiveComponent ComponentHitByMatch, FHitResult HitResult);
event void FHitByMatchSticky(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult);
event void FHitByMatchNonSticky(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult);
event void FHitByMatchOverlap(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult);

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Collision AssetUserData Tags")
class UMatchHitResponseComponent : UActorComponent
{
	UPROPERTY(Category = "MatchHitResponseComp", meta = (BPCannotCallEvent))
	FHitByMatchNonSticky OnNonStickyHit;

	UPROPERTY(Category = "MatchHitResponseComp", meta = (BPCannotCallEvent))
	FHitByMatchConsumed OnConsumed;

	UPROPERTY(Category = "MatchHitResponseComp", meta = (BPCannotCallEvent))
	FHitByMatchSticky OnStickyHit;

	UPROPERTY(Category = "MatchHitResponseComp", meta = (BPCannotCallEvent))
	FHitByMatchSticky OnOverlap;

}