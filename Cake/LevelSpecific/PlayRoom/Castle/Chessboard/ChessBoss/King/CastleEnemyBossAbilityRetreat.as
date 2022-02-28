import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessBossAbilityRetreat : UChessBossAbility
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default BossAbility.Priority = EBossAbilityPriority::High;
	default Cooldown = 2.f;

	AChessboard Chessboard;

	bool bActivated = false;
	bool bFinished = false;

	UPROPERTY()
	FHazeTimeLike StartTimelike;
	default StartTimelike.Duration = 1.5f;

	const float StartJumpHeight = 1000.f;

	FVector StartLocation;
	FVector TargetLocation;
	FVector2D TargetGridPosition;

	bool bTilesSet = false;

	UPROPERTY()
	TArray<FChessRetreatData> ChessRetreatLayouts;
	FChessRetreatData CurrentRetreatData;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Super::PreTick(DeltaTime);		
	}
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		StartTimelike.BindUpdate(this, n"OnStartUpdate");
		StartTimelike.BindFinished(this, n"OnStartFinished");
	}

	UFUNCTION()
	bool ShouldActivateAbility() const
	{
		if (ChessRetreatLayouts.Num() == 0)
			return false;

		if (bActivated)
			false;

		return true;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		// if (!bFinished)
		// 	return false;
		// if (TileSquareSpawns.Num() > 0)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Chessboard = PieceComp.Chessboard;
		bFinished = false;
		bActivated = true;

		SetCurrentRetreatData();

		StartLocation = Owner.ActorLocation;
		SetTargetLocation();

		TelegraphTiles(CurrentRetreatData.TilesToLower);
		StartTimelike.PlayFromStart();

		//Owner.BlockCapabilities(n"ChessboardMovement", this);
	}

	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Owner.UnblockCapabilities(n"ChessboardMovement", this);
		
		AbilitiesComp.AbilityFinished();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

		//UpdateAndExecuteSquare(DeltaTime);
	}

	void SetCurrentRetreatData()
	{
		int RandomInt = FMath::RandRange(0, ChessRetreatLayouts.Num() - 1);
		CurrentRetreatData = ChessRetreatLayouts[RandomInt];
	}

	void SetTargetLocation()
	{
		TargetGridPosition = CurrentRetreatData.BossGridPosition;
		TargetLocation = Chessboard.GetSquareCenter(TargetGridPosition);
	}

	UFUNCTION()
	void OnStartUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartLocation, TargetLocation, Value);
		NewLocation.Z += StartJumpHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnStartFinished()
	{
		Owner.SetActorLocation(TargetLocation);
		PieceComp.LandOnPosition(TargetGridPosition);

		LowerTiles(CurrentRetreatData.TilesToLower);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.SetActorLocation(Chessboard.GetSquareCenter(CurrentRetreatData.PlayerGridPosition));
		}
	}

	void TelegraphTiles(TArray<FVector2D> TilesToTelegraph)
	{
		for (FVector2D Tile : TilesToTelegraph)
		{
			Chessboard.GetTileActor(Tile).TelegraphTile(StartTimelike.Duration);
		}
	}

	void LowerTiles(TArray<FVector2D> TilesToLower)
	{
		for (FVector2D Tile : TilesToLower)
		{
			Chessboard.GetTileActor(Tile).DropTile(5000.f);
		}
	}

	void RaiseTiles(TArray<FVector2D> TilesToRaise)
	{
		for (FVector2D Tile : TilesToRaise)
		{
			Chessboard.GetTileActor(Tile).RestoreTile();
		}
	}
}

struct FChessRetreatData
{
	UPROPERTY()
	FVector2D BossGridPosition;

	UPROPERTY()
	FVector2D PlayerGridPosition;

	UPROPERTY()
	TArray<FVector2D> TilesToLower;	
}