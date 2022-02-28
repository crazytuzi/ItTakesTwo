event void FOnGiftExploded(UMagneticGiftComponent Component);

class UMagneticGiftComponent : UActorComponent
{
	UPROPERTY()
	FOnGiftExploded OnGiftExploded;

	UPROPERTY()
	bool bActivated;

	void Explode()
	{
		OnGiftExploded.Broadcast(this);
	}
}