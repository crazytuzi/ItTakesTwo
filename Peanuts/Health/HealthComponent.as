
/**
 * Should only contain health. Additional features should be in separate components.
 *
 * The idea is that other actors/components will look for this component on actors
 * that are supposed to take damage. Upon finding a Health component they'll 
 * call upon TakeDamage() which will reduce the health and notify everyone 
 * else that have subscribed to the health components delegate/events
 */

delegate void FOnTakeDamageDelegateSignature(AHazeActor HitBy, float Damage, FHitResult HitResult);
event void FOnTakeDamageEventSignature(float Damage);

UCLASS(HideCategories = "Cooking Collision ComponentReplication Sockets")
class UHealthComponent : UActorComponent
{
	default bAutoActivate = true;

	UPROPERTY(Category = "Health Events")
	FOnTakeDamageEventSignature DamageTakenEvent;

	UPROPERTY(Category = "Health Events")
	FOnTakeDamageDelegateSignature DamageTakenDelegate;

	/* -1 means infinite health */
	UPROPERTY(Category = "Health")
	float HP = 100.f;		

	void TakeDamage(const float Damage)
	{
		if (HP != -1)
		{
			HP -= Damage;
			HP = FMath::Max(0.f, HP);
			DamageTakenEvent.Broadcast(Damage);
		}
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable, Category = "Health")
	void OverrideableBlueprintEvent(AActor HitBy, const FHitResult& HitResult, const float Damage)
	{
		TakeDamage(Damage);
	}

	void OnHitCallBack(UPrimitiveComponent OurComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, FVector NormalImpulse, const FHitResult& Hit)
	{
		OverrideableBlueprintEvent(OtherActor, Hit, 1);
	}

}