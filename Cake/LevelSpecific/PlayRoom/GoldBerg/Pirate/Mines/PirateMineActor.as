// import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;
// import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
// import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;

// UCLASS(Abstract)
// class APirateMineActor : AHazeActor
// {
// 	UPROPERTY(RootComponent, DefaultComponent)
// 	USceneComponent Root;

// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	UHazeSkeletalMeshComponentBase SkeletalMesh;

// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	USphereComponent DetectionCollider;
	
// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	USphereComponent ExplosionCollider;

// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	USphereComponent BlockingCollider;
// 	default BlockingCollider.SetCollisionProfileName(n"BlockAll");

// 	UPROPERTY(DefaultComponent)
// 	UCannonBallDamageableComponent CannonBallDamageableComponent;
	
// 	UPROPERTY(DefaultComponent, NotEditable)
// 	UHazeAkComponent AkComponent;

// 	UPROPERTY(DefaultComponent)
// 	UPirateEnemyComponent EnemyComponent;

// 	UPROPERTY(Category = "Audio")
// 	UAkAudioEvent PirateMineFloatUpEvent;

// 	UPROPERTY(Category = "Audio")
// 	UAkAudioEvent PirateMineExplodeEvent;

// 	UPROPERTY(Category = "Audio")
// 	UAkAudioEvent PirateMineImpactEvent;
	
// 	UPROPERTY(Category = "Animation")
// 	FHazePlaySequenceData FloatUpAnimation;

// 	bool bOnSurface = false;

// 	float VerticalSpeed = 4.0f;

// 	float StartZLocation = -850.0f;

// 	// UPROPERTY(DefaultComponent, Attach = Root)
// 	// USphereComponent ExplosionCollider;

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		AkComponent.SetStopWhenOwnerDestroyed(false);
// 		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"OnMineExploded");

// 		if(!HasControl())
// 			return;
// 		ExplosionCollider.OnComponentBeginOverlap.AddUFunction(this, n"OverlappedExplosionCollision");
// 	}

// 	UFUNCTION()
// 	void PostFloatUpAudioEvent()
// 	{
// 		AkComponent.HazePostEvent(PirateMineFloatUpEvent);
// 	}

// 	UFUNCTION()
// 	void OnMineExploded()
// 	{
// 		AkComponent.HazePostEvent(PirateMineExplodeEvent);
// 	}

// 	UFUNCTION(NotBlueprintCallable)
// 	void OverlappedExplosionCollision(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
// 	{
// 		AWheelBoatActor Boat = Cast<AWheelBoatActor>(OtherActor);

// 		if (Boat == nullptr)
// 			return;

// 		NetBoatHitMine(Boat);		
// 	}

// 	UFUNCTION(NetFunction)
// 	void NetBoatHitMine(AWheelBoatActor Boat)
// 	{
// 		Boat.BoatWasHit(1.0f);
// 		AkComponent.HazePostEvent(PirateMineImpactEvent);
// 		CannonBallDamageableComponent.Explode();
// 	}
// }