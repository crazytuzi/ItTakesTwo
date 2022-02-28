import Cake.LevelSpecific.SnowGlobe.Mountain.ExplodingIce;

event void FWindWalkDoublePullHazardEvent(AWindWalkDoublePullHazard Hazard);

class AWindWalkDoublePullHazard : AExplodingIce
{
	default BreakableComponent.DefaultScatterForce = 10.f;
	default BreakableComponent.GroundCollision = false;

	UPROPERTY()
	FWindWalkDoublePullHazardEvent OnBrokenEvent;

	UPROPERTY()
	FWindWalkDoublePullHazardEvent OnReadyForRespawnEvent;

	UPROPERTY()
	float Speed = 4000.f;

	UPROPERTY()
	float SpeedRandomization = 400.f;

	UPROPERTY()
	TSubclassOf<UHazeCapability> MovementCapability;

	UPROPERTY(DefaultComponent)
	UBoxComponent CollisionBox;
	default CollisionBox.SetCollisionProfileName(n"OverlapAllDynamic");

	UPROPERTY()
	UNiagaraSystem SmashEffect;
	UNiagaraComponent SmashEffectComponent;

	FVector MoveDirection;
	FVector AutoDestructLocation;

	const float CooldownAfterBreak = 2.f;
	float ElapsedTime;

	private bool bIsBroken;
	bool bIsFlyingTowardsPlayer;

	bool bIsDeliberateMiss;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(BreakableComponent.StaticMesh == nullptr)
			return;

		CollisionBox.SetBoxExtent(BreakableComponent.StaticMesh.BoundingBox.Extent * 0.7f);
		CollisionBox.SetRelativeLocation(BreakableComponent.StaticMesh.BoundingBox.Center);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ensure(MovementCapability.IsValid(), "Add a valid movement capability!"))
			AddCapability(MovementCapability);

		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bIsBroken)
			return;

		ElapsedTime += DeltaTime;
		if(ElapsedTime >= CooldownAfterBreak)
		{
			bIsBroken = false;
			ElapsedTime = 0.f;

			SetActorHiddenInGame(true);

			OnReadyForRespawnEvent.Broadcast(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlaReason)
	{
		OnBrokenEvent.Clear();
		RemoveCapability(MovementCapability);

		MoveDirection = FVector::ZeroVector;
	}

	void Initialize(FVector SpawnLocation, FRotator SpawnRotation, bool bIsScriptedMiss)
	{
		bIsDeliberateMiss = bIsScriptedMiss;

		SetActorLocation(SpawnLocation);
		SetActorRotation(SpawnRotation);

		BreakableComponent.Reset();	
		SetActorHiddenInGame(false);
	}

	void StartMoving(FVector Direction, FVector AutoDestroyAtLocation)
	{
		MoveDirection = Direction;
		AutoDestructLocation = AutoDestroyAtLocation;

		bIsFlyingTowardsPlayer = true;
	}

	void BreakHazard(FVector HitLocation)
	{
		// Stop moving
		bIsFlyingTowardsPlayer = false;

		FBreakableHitData BreakData;
		BreakData.DirectionalForce = MoveDirection * Speed;
		BreakData.HitLocation = HitLocation;
		BreakData.ScatterForce = BreakableComponent.DefaultScatterForce;

		BreakableComponent.Break(BreakData);
		Break();

		// Fire event
		OnBrokenEvent.Broadcast(this);

		// Play effects
		SmashEffectComponent = Niagara::SpawnSystemAtLocation(SmashEffect, HitLocation);

		ElapsedTime = 0.f;
		bIsBroken = true;
	}

	bool CanSpawn()
	{
		return bHidden;
	}

	bool ShouldLoseCameraFocus(FVector PlayersLocation)
	{
		// If hazard is scripted miss, lose focus once it's broken
		if(bIsDeliberateMiss)
			return bIsBroken;

		// Ignore if hazard is 1000 units behind players
		FVector HazardToPlayers = (PlayersLocation - ActorLocation).GetSafeNormal();
		return HazardToPlayers.DotProduct(MoveDirection) < 0.f && ActorLocation.Distance(PlayersLocation) > 1000.f;
	}
}