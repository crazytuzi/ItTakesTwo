import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.Mines.PirateMinePulsatingEffectComponent;

UCLASS(Abstract)
class APirateOctopusArtilleryActor : APirateShipActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent ExplosionCollider;
	default ExplosionCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPirateMinePulsatingEffectComponent PulsatingComp;

	FTimerHandle ActivationTimerHandle;
	float FloatUpDuration = 1.5f;
	float FloatUpOffset = -1000.0f;
	bool bFloatingUp = false;

	float DamageAmount = 2.f;

	float Distance;
	float MinDistance;
	bool bExploded = false;

	FHazeAudioEventInstance FloatUpEventInstance;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ArtilleryFloatUpEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ArtilleryImpactEvent;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript() override
	{
		Super::ConstructionScript();
		EnemyComponent.AddBeginOverlap(ExplosionCollider, this, n"ExplosionColliderOverlapped");
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		bStartWithOctopusMH = false;
		Super::BeginPlay();
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);
		ExplosionCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CannonShootFromPosition.AttachToComponent(OctopusMesh, NAME_None, EAttachmentRule::KeepWorld);
		AkComponent.SetStopWhenOwnerDestroyed(true);

		PulsatingComp.SetPulsatingSkeletalMesh(OctopusMesh);
	}

	UFUNCTION(NotBlueprintCallable)
	void ExplosionColliderOverlapped(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		if(Boat.HasControl())
			NetBoatHitOctopusArtillery();
	}

	UFUNCTION(NetFunction)
	void NetBoatHitOctopusArtillery()
	{
		WheelBoat.BoatWasHit(DamageAmount, EWheelBoatHitType::CannonBall);
		PlayImpactAudioEvent();
		CannonBallDamageableComponent.Explode();
	}

	UFUNCTION()
    void OnShipExploded() override
    {
		DeactivateBoat();
		//BlockCapabilities(n"PirateEnemy", this);
		OnPirateShipExploded.Broadcast(this);
		UHazeAkComponent::HazePostEventFireForget(PirateShipDestroyEvent, this.GetActorTransform());
		bExploded = true;
	}

	UFUNCTION()
	void DeactivateBoat() override
	{
		Super::DeactivateBoat();

		PulsatingComp.DeactivatePulsatingEffect();
		SetActorHiddenInGame(true);		
	}

	UFUNCTION()
	void ActivatePirateShip() override
	{
		OctopusBabyComp.SetNextOctopusBabyAnimation(ESquidState::MH);
				
		Super::ActivatePirateShip();
		bFloatingUp = false;
		CannonBallDamageableComponent.ResetAfterExploding();

		ExplosionCollider.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		SetActorEnableCollision(true);
		PulsatingComp.ActivatePulsatingEffect();
	}

	UFUNCTION()
	void FloatUp(FVector NewLocation)
	{
		if(HasControl())
		{
			NetFloatUp(NewLocation);
		}
	}

	UFUNCTION(NetFunction)
	void NetFloatUp(FVector NewLocation)
	{
		SetActorLocation(NewLocation);

		bFloatingUp = true;

		FVector FloatUpLocation = NewLocation;
		FloatUpLocation.Z += FloatUpOffset;

		SetActorLocation(FloatUpLocation);
		MeshOffsetComponent.FreezeAndResetWithTime(FloatUpDuration);
		SetActorLocation(NewLocation);
		PlayFloatUpAudioEvent();

		SetActorHiddenInGame(false);
		ActivationTimerHandle = System::SetTimer(this, n"ActivatePirateShip", FloatUpDuration, false);
	}

	UFUNCTION()
    void PlayFloatUpAudioEvent()
    {
		FloatUpEventInstance = AkComponent.HazePostEvent(ArtilleryFloatUpEvent);
    }

	UFUNCTION()
    void PlayImpactAudioEvent()
    {
		AkComponent.HazePostEvent(ArtilleryImpactEvent);
		PrintToScreenScaled("artillery impact", 2.f, FLinearColor :: LucBlue, 2.f);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AkComponent.HazeStopEvent(FloatUpEventInstance.PlayingID);
	}
}