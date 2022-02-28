import Cake.LevelSpecific.Clockwork.Actors.Clocktower.LeakingWaterbucket;

event void FOnFirePutOut();

class AClockworkFire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireFX01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireFX02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireFX03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireFX04;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireFX05;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;

	UPROPERTY()
	FOnFirePutOut OnFirePutOut;

	bool bFirePutOut = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"SphereCollisionOverlap");
	}

	UFUNCTION()
	void SphereCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (bFirePutOut)
			return;
		
		ALeakingWaterBucket Bucket = Cast<ALeakingWaterBucket>(OtherActor);
		if(Bucket == nullptr)
			return;
		
		if(Bucket.PlayerHoldingBucket == nullptr)
			return;

		if(!Bucket.PlayerHoldingBucket.HasControl())
			return;

		UBoxComponent Box = Cast<UBoxComponent>(OtherComponent);
		if(Box == nullptr)
			return;

		if(Bucket.GetWaterLevel() <= 0.f)
			return;

		NetPutOutFire(Bucket);
	}

	UFUNCTION(NetFunction)
	void NetPutOutFire(ALeakingWaterBucket Bucket)
	{	
		if (bFirePutOut)
			return;

		FireFX01.Deactivate();
		FireFX02.Deactivate();
		FireFX03.Deactivate();
		FireFX04.Deactivate();
		FireFX05.Deactivate();
		bFirePutOut = true;
		OnFirePutOut.Broadcast();
		Bucket.ForcePlayerToDropBucket();
		Bucket.EmptyWaterInBucket();
		Bucket.DestroyActor();
	}
}