import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessBossAbilityTileWave : UChessBossAbility
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
	FVector2D TargetCoordinate;

	TArray<FVector2D> Locations;
	default Locations.Add(FVector2D(1.f, 1.f));
	default Locations.Add(FVector2D(1.f, 6.f));
	default Locations.Add(FVector2D(6.f, 1.f));
	default Locations.Add(FVector2D(6.f, 6.f));

	TArray<FTileSquareGroupTimer> TileSquareSpawns;

	bool bTilesSet = false;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Super::PreTick(DeltaTime);

		if (PieceComp.State == EChessPieceState::Fighting)
			GetSquareOfTilesAtDistanceAwayFromGridLocation(PieceComp.GridPosition);
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
		if (bActivated)
			false;

		return true;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (!bFinished)
			return false;
		if (TileSquareSpawns.Num() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Chessboard = PieceComp.Chessboard;
		bFinished = false;
		bActivated = true;

		StartLocation = Owner.ActorLocation;
		SetTargetLocation();

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

		UpdateAndExecuteSquare(DeltaTime);
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
		PieceComp.LandOnPosition(TargetCoordinate);
		SetTileSquareSpawns();
		bFinished = true;
	}

	void SetTargetLocation()
	{
		/*
		Get the two quadants of the chessboard that don't have a player in them
		*/
		TPerPlayer<FVector2D> PlayerGridPositions;
		TArray<FVector2D> PossibleLocations = Locations;

		// Get the players' grid pos
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FVector2D PlayerGridPosition;
			PieceComp.Chessboard.GetGridPosition(Player.ActorLocation, PlayerGridPosition);
			PlayerGridPositions[Player] = PlayerGridPosition;
		}

		// Remove the quadrants that the players are in (they could be in the same quadrant)
		for (int Index = Locations.Num() - 1; Index >= 0; Index--)
		{
			for (auto PlayerLocation : PlayerGridPositions)
			{
				float X = FMath::Abs(PossibleLocations[Index].X - PlayerLocation.X);
				float Y = FMath::Abs(PossibleLocations[Index].Y - PlayerLocation.Y);

				if (X < (PieceComp.Chessboard.GridSize.X / 2.f) - 1.f && Y < (PieceComp.Chessboard.GridSize.Y / 2.f) - 1.f)
				{
					PossibleLocations.Remove(Locations[Index]);
					break;
				}
			}			
		}

		// Pick a random location in a quadrant that the players arent in
		int Index = FMath::RandRange(0, PossibleLocations.Num() - 1);
		TargetCoordinate = PossibleLocations[Index];
		TargetLocation = PieceComp.Chessboard.GetSquareCenter(TargetCoordinate);

		DebugDrawLine(TargetLocation, TargetLocation + FVector::UpVector * 250.f, Duration = 2.f, Color = FLinearColor::Green, Thickness = 4.f);

		StartTimelike.PlayFromStart();
	}

	void SetTileSquareSpawns()
	{
		TileSquareSpawns.Empty();

		float TimeBetweenSteps = 0.11f;
		int Steps = 6;

		for (int Index = 0; Index < Steps; Index++)
		{
			FTileSquareGroupTimer TileSquare;
			TileSquare.TileCoordinates = GetSquareOfTilesAtDistanceAwayFromGridLocation(PieceComp.GridPosition, 1 + Index);
			TileSquare.Duration = TimeBetweenSteps * Index;

			if (TileSquare.TileCoordinates.Num() == 0)
				break;

			TileSquareSpawns.Add(TileSquare);
		}
	}

	void UpdateAndExecuteSquare(float DeltaTime)
	{
		if (TileSquareSpawns.Num() == 0)
			return;

		for (int Index = TileSquareSpawns.Num() - 1; Index >= 0; Index--)
		{
			TileSquareSpawns[Index].Duration -= DeltaTime;

			if (TileSquareSpawns[Index].Duration <= 0.f)
			{
				LowerSquare(TileSquareSpawns[Index].TileCoordinates);
				TileSquareSpawns.RemoveAt(Index);
			}
		
		}
	}

	void LowerSquare(TArray<FVector2D> TileSquare)
	{
		for (FVector2D Tile : TileSquare)
		{
			Chessboard.GetTileActor(Tile).DropTile(1.5f);
		}
	}


	TArray<FVector2D> GetSquareOfTilesAtDistanceAwayFromGridLocation(FVector2D GridLocation, int DistanceFromLocation = 1)
	{
		TArray<FVector2D> GridsInSquare;		

		// Get the two rows in X
		for (int Index = GridLocation.X - DistanceFromLocation; Index <= GridLocation.X + DistanceFromLocation; Index++)
		{
			FVector2D LowerGridLocation = FVector2D(Index, GridLocation.Y - DistanceFromLocation);
			if (PieceComp.Chessboard.IsGridPositionValid(LowerGridLocation))
				GridsInSquare.Add(LowerGridLocation);
			
			FVector2D UpperGridLocation = FVector2D(Index, GridLocation.Y + DistanceFromLocation);
			if (PieceComp.Chessboard.IsGridPositionValid(UpperGridLocation))
				GridsInSquare.Add(UpperGridLocation);
		}

		// Get the two columns in Y
		for (int Index = GridLocation.Y - DistanceFromLocation + 1; Index <= GridLocation.Y + DistanceFromLocation - 1; Index++)
		{
			FVector2D LowerGridLocation = FVector2D(GridLocation.X - DistanceFromLocation, Index);
			if (PieceComp.Chessboard.IsGridPositionValid(LowerGridLocation))
				GridsInSquare.Add(LowerGridLocation);
			
			FVector2D UpperGridLocation = FVector2D(GridLocation.X + DistanceFromLocation, Index);
			if (PieceComp.Chessboard.IsGridPositionValid(UpperGridLocation))
				GridsInSquare.Add(UpperGridLocation);
		}

		// for (auto Grid : GridsInSquare)
		// {
		// 	FVector Location = PieceComp.Chessboard.GetSquareCenter(Grid);
		// 	DebugDrawLine(Location, Location + FVector::UpVector * 250.f, Duration = 0.f, Color = FLinearColor::Red, Thickness = 4.f);
		// }

		return GridsInSquare;
	}
}



