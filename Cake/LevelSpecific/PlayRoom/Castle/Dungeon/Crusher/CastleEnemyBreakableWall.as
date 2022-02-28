import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.Environment.BreakableComponent;
import Peanuts.DamageFlash.DamageFlashStatics;

class ACastleEnemyBreakableWall : ACastleEnemy
{
	default MusicIntensityType = ECastleEnemyMusicIntensityType::None;
	default bCanAggro = false;

	UPROPERTY(DefaultComponent)
	UBreakableComponent BreakableComponent;

	UPROPERTY(DefaultComponent)
	UBoxComponent OverlapBox;
	default OverlapBox.SetCollisionProfileName(n"OverlapAll");
	default OverlapBox.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
	//default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);

	//default BoxComp.bGenerateOverlapEvents = false;	

	UPROPERTY(Category = "Castle Enemy Breakable")
	TArray<ACastleEnemyBreakableWall> LinkedBreakableWalls;

	/* Breakable asset. */
	UPROPERTY(Category = "Castle Enemy Breakable")
	UDataAssetBreakable BreakablePreset;

	/* How long it waits before despawning the broken chunks. */
	UPROPERTY(Category = "Castle Enemy Breakable")
	float DespawnTimerAfterDeath = 5.f;

	UPROPERTY()
	bool bReactToDamage = false;

	FHazeAcceleratedVector SprungOffset;

	UFUNCTION(BlueprintEvent)
	void BreakBreakable(FVector DeathDirection) {}

	void AddDefaultCapabilities() override
	{
        AddCapability(n"CastleEnemyHealthCapability");
        AddCapability(n"CastleEnemyBreakableDeathCapability");
		if (BurningDPS > 0.f)
			AddCapability(n"CastleEnemyBurnCapability");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		BlockCapabilities(n"Movement", this);

		if (bReactToDamage)
			OnTakeDamage.AddUFunction(this, n"OnBreakableTakeDamage");
		OnKilled.AddUFunction(this, n"OnBreakableWallKilled");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BreakableComponent.BreakablePreset = BreakablePreset;
		BreakableComponent.ConstructionScript_Hack();

		if (BreakablePreset != nullptr && BreakablePreset.Mesh != nullptr)
		{
			OverlapBox.BoxExtent = BreakablePreset.Mesh.BoundingBox.Extent;
			OverlapBox.RelativeLocation = BreakablePreset.Mesh.BoundingBox.Center;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateStatusEffects(DeltaTime);

		SprungOffset.SpringTo(FVector::ZeroVector, 3000.f, 0.1f, DeltaTime);
		BreakableComponent.SetRelativeLocation(SprungOffset.Value);
	}

	UFUNCTION()
	void OnBreakableTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event)
	{
		Flash(BreakableComponent);

		FVector Direction;
		if (Event.HasDirection())
			Direction = Event.DamageDirection;
		else
			Direction = (ActorLocation - Event.DamageSource.ActorLocation);
		Direction.Normalize();
		Direction = ActorTransform.InverseTransformVector(Direction);

		SprungOffset.Velocity += Direction * 1000.f;
	}

	UFUNCTION()
	void OnBreakableWallKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		for (ACastleEnemyBreakableWall BreakableWall : LinkedBreakableWalls)
		{
			if (BreakableWall == nullptr)
				continue;
			BreakableWall.Kill();
		}
	}

	// void KillInternal(bool bKilledByDamage)
	// {
	// 	Super::KillInternal(bKilledByDamage);

	// 	FBreakableHitData BreakableData;
	// 	BreakableData.HitLocation = Breakable.Owner.ActorLocation;
	// 	//BreakableData.DirectionalForce = (Breakable.Owner.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal() * 5.f;
	// 	BreakableData.ScatterForce = 5.f;

	// 	Breakable.Hit(BreakableData);
	// }
}