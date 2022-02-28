import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

UCLASS(Abstract)
class ACastleEnemyQueenHeavensFury : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent DamageCapsule;

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;
	TPerPlayer<float> DamageTickTimer;

	UPROPERTY()
	float MoveSpeed = 400.f;

	UPROPERTY()
	float DamagePerTick = 8;

	UPROPERTY()
	float TicksPerSecond = 5;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MoveTowardsTarget(DeltaTime);

		if (DamagePerTick != 0)
			DamageOverlappingPlayers(DeltaTime);
	}

	void MoveTowardsTarget(float DeltaTime)
	{
		if (TargetPlayer == nullptr)
			return;

		FVector MoveDirection = TargetPlayer.ActorLocation - ActorLocation;

		FVector DeltaMovement;
		if (MoveDirection.Size() <= MoveSpeed * DeltaTime)
			DeltaMovement = MoveDirection;
		else
			DeltaMovement = MoveDirection.GetSafeNormal() * MoveSpeed * DeltaTime;

		AddActorWorldOffset(DeltaMovement);
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