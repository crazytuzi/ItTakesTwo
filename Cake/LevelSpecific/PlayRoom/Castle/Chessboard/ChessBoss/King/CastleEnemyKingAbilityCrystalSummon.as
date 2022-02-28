import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessKingAbilityCrystalSummon : UChessBossAbility
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default Cooldown = 10.f;
	default BossAbility.Priority = EBossAbilityPriority::High;

	UPROPERTY()
	FHazeTimeLike EnterTimelike;
	default EnterTimelike.Duration = 1.6f;
	//const float JumpHeight = 1200.f;

	// UPROPERTY()
	// TSubclassOf<UCameraShakeBase> JumpLandCameraShake;
	// UPROPERTY()
	// FRuntimeFloatCurve VerticalMovement;

	FVector StartLocation;
	FVector TargetLocation;

	bool bInLocation = false;

	UPROPERTY()
	TSubclassOf<ACastleEnemy> CrystalType;
	TArray<ACastleEnemy> SpawnedCrystals;
	const int NumberOfCrystalsToSpawn = 8;
	const float SpawnCooldown = 1.25f;
	const float CrystalSpeed = 120.f;
	const float DamageOnExplode = 20.f;

	float SpawnCooldownCurrent = SpawnCooldown;
	int NumberOfCrystalsSpawned = 0;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		EnterTimelike.BindUpdate(this, n"OnEnterUpdate");
		EnterTimelike.BindFinished(this, n"OnEnterFinished");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.BlockCapabilities(n"ChessboardMovement", this);
		Owner.BlockCapabilities(n"CastleEnemyFalling", this);

		bInLocation = false;
		SpawnCooldownCurrent = 0.f;
		NumberOfCrystalsSpawned = 0;

		StartLocation = Owner.ActorLocation;
		TargetLocation = (PieceComp.Chessboard.TopLeft + PieceComp.Chessboard.BotRight) / 2.f;

		OwningBoss.bInvulnerable = true;

		EnterTimelike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
		Owner.UnblockCapabilities(n"CastleEnemyFalling", this);

		OwningBoss.bInvulnerable = false;

		AbilitiesComp.AbilityFinished();
		CurrentCooldown = Cooldown;
	}

	UFUNCTION()
	void OnEnterUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartLocation, TargetLocation, Value);
		//NewLocation.Z += VerticalMovement.GetFloatValue(Value) * JumpHeight;
		//NewLocation.Z += JumpHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		Owner.SetActorLocation(TargetLocation);
		bInLocation = true;

		// if (JumpLandCameraShake.IsValid())
		// 	Game::GetMay().PlayCameraShake(JumpLandCameraShake, 10.f);
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (NumberOfCrystalsSpawned < NumberOfCrystalsToSpawn)
			return false;

		if (SpawnedCrystals.Num() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (bInLocation && NumberOfCrystalsSpawned < NumberOfCrystalsToSpawn)
		{
			SpawnCooldownCurrent += DeltaTime;

			if (SpawnCooldownCurrent >= SpawnCooldown)
				SpawnCrystal();				
		}

		MoveCrystals(DeltaTime);
	}	

	void MoveCrystals(float DeltaTime)
	{
		for (int Index = SpawnedCrystals.Num() - 1; Index >= 0; Index--)
		{
			ACastleEnemy Crystal = SpawnedCrystals[Index];

			FVector ToOwner = Owner.ActorLocation - Crystal.ActorLocation;

			float DistanceToTarget = ToOwner.Size();
			FVector MoveDirection = ToOwner.GetSafeNormal();
			FVector DeltaMove = MoveDirection * CrystalSpeed * DeltaTime;
			
			if ((DistanceToTarget - DeltaMove.Size()) > 50.f)
				Crystal.AddActorWorldOffset(DeltaMove);
			else
				ExplodeCrystal(Crystal);
		}
	}

	void ExplodeCrystal(ACastleEnemy Crystal)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FCastlePlayerDamageEvent Evt;
			Evt.DamageSource = OwningBoss;
			Evt.DamageDealt = DamageOnExplode;
			Evt.DamageLocation = Player.ActorCenterLocation;
			Evt.DamageDirection = Math::ConstrainVectorToPlane(Player.ActorLocation - Owner.ActorLocation, FVector::UpVector);
			//Evt.DamageEffect = DamageEffect;

			Player.DamageCastlePlayer(Evt);
		}

		SpawnedCrystals.Remove(Crystal);
		Crystal.DestroyActor();	
	}

	void SpawnCrystal()
	{
		NumberOfCrystalsSpawned += 1;
		SpawnCooldownCurrent = 0.f;

		int X = FMath::RandRange(0.f, PieceComp.Chessboard.GridSize.X - 1.f);
		int Y = FMath::RandBool() ? 0.f : PieceComp.Chessboard.GridSize.Y - 1.f;

		FVector2D Coordinate = FVector2D(X, Y);
		if (FMath::RandBool())
			Coordinate = FVector2D(Coordinate.Y, Coordinate.X);

		FVector SpawnLocation = PieceComp.Chessboard.GetSquareCenter(Coordinate);

		ACastleEnemy SpawnedCrystal = Cast<ACastleEnemy>(SpawnActor(CrystalType, SpawnLocation));
		SpawnedCrystals.Add(SpawnedCrystal);
		SpawnedCrystal.OnKilled.AddUFunction(this, n"OnCrystalKilled");
		SpawnedCrystal.BlockCapabilities(n"CastleEnemyMovement", this);
	}

	UFUNCTION()
	void OnCrystalKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		SpawnedCrystals.Remove(Enemy);
	}
}