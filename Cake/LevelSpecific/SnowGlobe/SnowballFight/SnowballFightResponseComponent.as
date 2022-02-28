event void FOnSnowballFightResponseHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity);

class USnowballFightResponseComponent : UActorComponent
{
	bool bCanTakeDamage = true;

	UPROPERTY()
	FOnSnowballFightResponseHit OnSnowballHit;
}