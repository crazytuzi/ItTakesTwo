import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyChessBossExplodingOrb;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.King.CastleEnemyBossTransitionSlam;

class UCastleEnemyChessBossAbilitySlamTransition : UChessBossAbility
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default BossAbility.Priority = EBossAbilityPriority::High;

	AChessboard Chessboard;

	bool bActivated = false;
	bool bFinished = false;

	UPROPERTY()
	TSubclassOf<ACastleEnemyBossTransitionSlam> TransitionSlamType;

	UPROPERTY()
	FHazeTimeLike StartSlamTimelike;
	default StartSlamTimelike.Duration = 1.5f;

	FHazeTimeLike SlamTimelike;
	default SlamTimelike.Duration = 1.f;

	const float StartSlamHeight = 1000.f;

	FVector StartSlamLocation;
	FVector EndSlamLocation;
	FVector2D SlamCoordinate;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		StartSlamTimelike.BindUpdate(this, n"OnStartSlamUpdate");
		StartSlamTimelike.BindFinished(this, n"OnStartSlamFinished");

		SlamTimelike.BindUpdate(this, n"OnSlamUpdate");
		SlamTimelike.BindFinished(this, n"OnSlamFinished");
	}

	UFUNCTION()
	bool ShouldActivateAbility() const
	{
		if (bActivated)
			false;

		return true;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (bFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Chessboard = PieceComp.Chessboard;

		bActivated = true;

		FVector2D GridSize = Chessboard.GridSize;
		FVector2D TopLeftTileCoordinate = FVector2D(GridSize.X - 1.f, GridSize.Y - 1.f);
		FVector2D TopRightTileCoordinate = FVector2D(0.f, GridSize.Y - 1.f);

		StartSlamLocation = Owner.ActorLocation;
		EndSlamLocation = (Chessboard.GetSquareCenter(TopLeftTileCoordinate) + Chessboard.GetSquareCenter(TopRightTileCoordinate)) / 2.f;

		//StartSlamTimelike.PlayFromStart();

		System::SetTimer(this, n"Slam", 1.6f, true, 0.f, 0.f);
	}

	UFUNCTION()
	void Slam()
	{
		SlamCoordinate = GetRandomSlamLocation();
		StartSlamLocation = Owner.ActorLocation;
		EndSlamLocation = Chessboard.GetSquareCenter(SlamCoordinate);

		SlamTimelike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AbilitiesComp.AbilityFinished();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

	}

	UFUNCTION()
	void OnStartSlamUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartSlamLocation, EndSlamLocation, Value);
		NewLocation.Z += StartSlamHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnStartSlamFinished()
	{
		Owner.SetActorLocation(EndSlamLocation);
		SpawnSlamWave(GetRandomSlamLocation());
	}

	UFUNCTION()
	void OnSlamUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartSlamLocation, EndSlamLocation, Value);
		NewLocation.Z += StartSlamHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnSlamFinished()
	{
		Owner.SetActorLocation(EndSlamLocation);
		SpawnSlamWave(SlamCoordinate);
	}

	FVector2D GetRandomSlamLocation()
	{
		float MinGridPos = 1.f;
		float MaxGridPos = Chessboard.GridSize.X - 2.f;
		float GridPos = FMath::RoundToFloat(FMath::RandRange(MinGridPos, MaxGridPos));

		return FVector2D(GridPos, Chessboard.GridSize.X - 1.f);
	}

	void SpawnSlamWave(FVector2D SlamCoordinate)
	{
		FVector2D ChessBoardDirection = FVector2D(0.f, -1.f);

		FVector SpawnLocation = Chessboard.GetSquareCenter(SlamCoordinate);
		FVector MoveDirection = Chessboard.GetSquareCenter(SlamCoordinate + ChessBoardDirection) - SpawnLocation;

		FRotator SpawnRotation = FRotator::MakeFromX(MoveDirection);		
		ACastleEnemyBossTransitionSlam Slam = Cast<ACastleEnemyBossTransitionSlam>(SpawnActor(TransitionSlamType, SpawnLocation, SpawnRotation));
		Slam.StartSlam(Chessboard);
	}
}