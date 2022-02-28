import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

UCLASS(Abstract)
class ACastleEnemyQueenSpinAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent DamageCapsule;
	default DamageCapsule.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	default SetActorHiddenInGame(true);

	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;
	TPerPlayer<float> DamageTickTimer;

	UPROPERTY()
	float DamagePerTick = 16;

	UPROPERTY()
	float TicksPerSecond = 4;

	UFUNCTION(BlueprintEvent)
	void EnableSpinAttack()
	{
		SetActorHiddenInGame(false);
		DamageCapsule.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION(BlueprintEvent)
	void DisableSpinAttack()
	{
		SetActorHiddenInGame(true);
		DamageCapsule.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DamagePerTick != 0)
			DamageOverlappingPlayers(DeltaTime);
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