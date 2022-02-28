
event void FOnIgnited(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult);

UCLASS(HideCategories = "Cooking ComponentReplication Sockets Collision AssetUserData Tags")
class UCombustibleComponent : UActorComponent
{
 	UPROPERTY(Category = "Combustible", meta = (BPCannotCallEvent))
	FOnIgnited OnIgnited;
}