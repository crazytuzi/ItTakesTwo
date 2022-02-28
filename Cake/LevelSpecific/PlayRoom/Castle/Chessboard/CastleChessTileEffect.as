import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
class ACastleChessTileEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComponent;
	default BoxComponent.SetCollisionProfileName(n"OverlapOnlyPawn");
	default BoxComponent.SetBoxExtent(FVector(150, 150, 80), false);
	default BoxComponent.SetRelativeLocation(FVector(0.f, 0.f, 80.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraComponent;

	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	TPerPlayer<float> DamageTickTimer;

	UPROPERTY()
	float Duration = 3.f;
	float DurationCurrent = 0.f;

	UPROPERTY()
	float DamagePerTick = 20;

	UPROPERTY()
	float TicksPerSecond = 5;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DamagePerTick != 0)
			DamageOverlappingPlayers(DeltaTime);
		UpdateDuration(DeltaTime);		
	}

	void DamageOverlappingPlayers(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : OverlappingPlayers)
		{
			DamageTickTimer[Player] -= DeltaTime;
			
			if (DamageTickTimer[Player] <= 0)
				DamagePlayer(Player);
		}
	}

	void DamagePlayer(AHazePlayerCharacter Player)
	{
		FCastlePlayerDamageEvent Damage;
		Damage.DamageDealt = DamagePerTick;
		Damage.DamageLocation = Player.ActorLocation;

		DamageTickTimer[Player] = 1 / TicksPerSecond;

		DamageCastlePlayer(Player, Damage);
	}

	void UpdateDuration(float DeltaTime)
	{
		DurationCurrent += DeltaTime;

		if (DurationCurrent >= Duration)
			DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if (OverlappingPlayer == nullptr)
			return;

		OverlappingPlayers.Add(OverlappingPlayer);
		DamagePlayer(OverlappingPlayer);
    }

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (OverlappingPlayer == nullptr)
			return;

		OverlappingPlayers.Remove(OverlappingPlayer);
    }
}