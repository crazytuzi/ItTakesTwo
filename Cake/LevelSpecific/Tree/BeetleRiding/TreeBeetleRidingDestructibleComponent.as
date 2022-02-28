event void FOnBeetleHit(FVector HitLocation, FVector ForceDirection);
event void FOnBeetleChargeHit(FVector HitLocation, FVector ForceDirection);


class UTreeBeetleRidingDestructibleComponent : UActorComponent
{
	UPROPERTY(meta = (NotBlueprintCallable))
	FOnBeetleHit OnBeetleHit;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnBeetleChargeHit OnBeetleChargeHit;
}