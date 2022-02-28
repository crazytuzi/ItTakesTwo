import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyAIAggroCapability : UHazeCapability
{
    // Whether to re-calculate which player should have aggro when taking damage
    UPROPERTY()
    bool bRecomputeAggroOnDamage = true;

	// Whether we should only aggro when the player is inside line of sight
	UPROPERTY()
	bool bAggroRequiresLineOfSight = true;

	// Any height difference more than this will invalidate aggro
	UPROPERTY()
	float MaxHeightDifference = 150.f;

    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyAggro");

	TPerPlayer<float> DamageTakenFromPlayer;

    ACastleEnemy Enemy;
	bool bTriggerRecalculate = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
        if (!bRecomputeAggroOnDamage)
			return;

		bTriggerRecalculate = true;

		auto PlayerSource = Cast<AHazePlayerCharacter>(Event.DamageSource);
		if (PlayerSource != nullptr)
			DamageTakenFromPlayer[PlayerSource] += Event.DamageDealt;
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if (Enemy.AggroedPlayer != nullptr && !bTriggerRecalculate)
            return;
		if (!HasControl())
			return;
		if (IsBlocked())
			return;
		if (Enemy.IsActorDisabled())
			return;

        AHazePlayerCharacter ClosestPlayer = nullptr;
		FVector EnemyLocation = Enemy.ActorLocation;

        float MinDistance = MAX_flt;
		float MaxDamage = -1.f;

        for (auto Player : Game::GetPlayers())
        {
			FVector PlayerLocation = Player.ActorLocation;

			if (MaxHeightDifference > 0.f && FMath::Abs(EnemyLocation.Z - PlayerLocation.Z) > MaxHeightDifference)
				continue;

            float Distance = PlayerLocation.Distance(EnemyLocation);
			if (Distance > Enemy.EnemyAggroRange)
				continue;

			if (Enemy.LeashRange > 0.f)
			{
				float LeashDistance = Enemy.LeashFromPosition.DistSquared2D(PlayerLocation);
				if (LeashDistance > FMath::Square(Enemy.LeashRange))
					continue;
			}

			if (bAggroRequiresLineOfSight && !Enemy.HasLineOfSightTo(Player))
				continue;
			if (!Enemy.CanTargetPlayer(Player))
				continue;

			// First try to target the player with the highest damage dealt to this enemy
			float DamageTaken = DamageTakenFromPlayer[Player];
			if (DamageTaken < MaxDamage)
				continue;

			// Then try to target the closest player if otherwise equal
			bool bBetterTarget = false;
			if (DamageTaken == MaxDamage)
				bBetterTarget = (Distance < MinDistance);
			else
				bBetterTarget = (DamageTaken > MaxDamage);

            if (bBetterTarget)
            {
                ClosestPlayer = Player;
				MaxDamage = DamageTaken;
                MinDistance = Distance;
            }
        }

        if (ClosestPlayer != nullptr && ClosestPlayer != Enemy.AggroedPlayer)
        {
            FCastleEnemyAggroFlags AggroFlags;
            AggroFlags.bAutomaticAggro = true;

            Enemy.AggroPlayer(ClosestPlayer, AggroFlags);
            if (Enemy.AllyGroupAggroRange > 0.f)
                Enemy.GroupAggroNearbyEnemies(Enemy.AllyGroupAggroRange, ClosestPlayer, AggroFlags);
        }

		bTriggerRecalculate = false;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (Enemy.AggroedPlayer != nullptr)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (Enemy.AggroedPlayer == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (Enemy.EnemyLoseAggroRange > 0.f && Enemy.AggroedPlayer != nullptr)
        {
            float Distance = Enemy.AggroedPlayer.ActorLocation.Distance(Enemy.ActorLocation);
            if (Distance > Enemy.EnemyLoseAggroRange)
            {
                Enemy.ClearAggro();
            }
        }

        if (Enemy.LeashRange > 0.f && Enemy.AggroedPlayer != nullptr)
        {
            float PlayerDistance = Enemy.AggroedPlayer.ActorLocation.DistSquared2D(Enemy.LeashFromPosition);
            float EnemyDistance = Enemy.ActorLocation.DistSquared2D(Enemy.LeashFromPosition);
            if (EnemyDistance > FMath::Square(Enemy.LeashRange) && PlayerDistance > EnemyDistance)
            {
                Enemy.ClearAggro();
            }
        }

        if (Enemy.AggroedPlayer != nullptr && MaxHeightDifference > 0.f)
        {
            float HeightDistance = FMath::Abs(Enemy.AggroedPlayer.ActorLocation.Z - Enemy.ActorLocation.Z);
            if (HeightDistance > MaxHeightDifference)
            {
                Enemy.ClearAggro();
            }
        }

		if (Enemy.AggroedPlayer != nullptr && !Enemy.CanTargetPlayer(Enemy.AggroedPlayer))
		{
			Enemy.ClearAggro();
		}
    }
};