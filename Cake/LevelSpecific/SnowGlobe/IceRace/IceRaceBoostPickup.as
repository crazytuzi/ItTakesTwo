import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceComponent;

class AIceRaceBoostPickup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoostAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpotAmbAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpotAmbAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RespawnAudioEvent;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;	

	UPROPERTY()
	UNiagaraSystem PickupEffect;

	UPROPERTY()
	float RespawnTime = 3.f;

	float RespawnTimer = 0.f;

	UPROPERTY()
	float BobHeight = 25.f;

	UPROPERTY()
	float BobSpeed = 2.f;

	UPROPERTY()
	float SpinSpeed = 90.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	
		VisualRoot.SetVisibility(false, true);
		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DisableActor(this);
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Pickup(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		VisualRoot.SetRelativeLocationAndRotation(FVector(0.f, 0.f, FMath::Sin(Time::GetGameTimeSeconds() * BobSpeed) * BobHeight), FRotator(0.f, Time::GetGameTimeSeconds() * SpinSpeed, 0.f));
	}

	UFUNCTION()
	void Pickup(AHazePlayerCharacter Player)
	{
		UIceRaceComponent IceRaceComponent = UIceRaceComponent::Get(Player);

		if (IceRaceComponent == nullptr)
			return;

		// Give boost
		IceRaceComponent.bHasBoost = true;
		Player.PlayerHazeAkComp.HazePostEvent(BoostAudioEvent);

		System::SetTimer(this, n"HandleRespawnTimerDone", RespawnTime, false);
		Niagara::SpawnSystemAtLocation(PickupEffect, ActorLocation, ActorRotation);

		Despawn();
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleRespawnTimerDone()
	{
		Spawn();
	}

	UFUNCTION()
	void Despawn()
	{
		VisualRoot.SetVisibility(false, true);
		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void Spawn()
	{
		Niagara::SpawnSystemAtLocation(SpawnEffect, ActorLocation, ActorRotation);

		VisualRoot.SetVisibility(true, true);
		Collision.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		HazeAkComp.HazePostEvent(RespawnAudioEvent);
	}

	UFUNCTION()
	void ActivatePickup()
	{
		EnableActor(this);
		HazeAkComp.HazePostEvent(PlaySpotAmbAudioEvent);
	}

	UFUNCTION()
	void DeactivatePickup()
	{
		DisableActor(this);
		System::ClearTimer(this, n"HandleRespawnTimerDone");
		HazeAkComp.HazePostEvent(StopSpotAmbAudioEvent);
	}
}