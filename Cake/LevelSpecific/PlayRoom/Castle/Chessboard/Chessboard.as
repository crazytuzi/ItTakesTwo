import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleDungeonVOBank;

event void FOnChessboardTurn(AChessboard Chessboard, int TurnNumber);
event void FOnChessPieceKilled(ACastleEnemy CastleEnemy);
event void FOnChessTileFallingStatusChange(AChessTile Tile, EChessTileFallingStatus FallingStatus);

enum EChessTileFallingStatus
{
	StartedFalling,
	FinishedFalling,
	StartedReturning,
	FinishedReturning
}

class AChessboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;

	// Interval in time between chess "turns"
	UPROPERTY()
	private float TurnInterval = 0.75f;

	// Amount of squares in the full grid around this point
	UPROPERTY()
	FVector2D GridSize;

	// Size in unreal units for one square
	UPROPERTY()
	FVector2D SquareSize;

	// Called every time a chess "turn" happens
	UPROPERTY()
	FOnChessboardTurn OnChessboardTurn;

	// Called whenever a chess piece is killed
	UPROPERTY()
	FOnChessPieceKilled OnChessPieceKilled;

	// Class used for chess tile actors
	UPROPERTY()
	TSubclassOf<AChessTile> TileActorClass = AChessTile::StaticClass();

	// Tile actors that the board has created for all the tiles
	UPROPERTY(EditConst)
	TArray<AChessTile> TileActors;

	// All chess pieces that are currently on this board
	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<ACastleEnemy> AllPieces;

	bool bChessboardDisabled = false;
	bool bKingAndQueenDisable = false;
	bool bTilesStartedDropping = false;

	UPROPERTY()
	FOnChessTileFallingStatusChange OnFallingTiles;

	// Current chess "turn"
	int CurrentTurn = 0;

	int EnemiesSpawned = 0;
	float TurnRemainingTime = 0.f;
	float CurrentSpeedMultiplier = 1.f;

	UPROPERTY()
	float TelegraphDuration = 2.f;

	bool bSpawningWaves = false;

	bool bBarkPlayed = false;

	UPROPERTY()
	UCastleDungeonVOBank VOBank;

	void PlayTelegraphBark(FName EventName)
	{
		if (bBarkPlayed)
			return;
		bBarkPlayed = true;		

		PlayFoghornVOBankEvent(VOBank, EventName);
	}

	UFUNCTION()
	void PermanentlyDisableChessboard()
	{
		bChessboardDisabled = true;
		for (auto Actor : AllPieces)
			Actor.DisableActor(this);
		for (auto Tile : TileActors)
		{
			Tile.SnapToTop();
			Tile.StopTremble();
		}
	}

	UFUNCTION()
	void CleanupChessFight(TArray<ACastleEnemy> IgnoredEnemies)
	{
		bChessboardDisabled = true;

		for (auto Tile : TileActors)
		{
			Tile.RestoreTile();
			Tile.StopTremble();
		}

		for (int Index = AllPieces.Num() - 1; Index > 0; Index--)
		{
			if (!IgnoredEnemies.Contains(AllPieces[Index]))
				AllPieces[Index].Kill();
		}
	}

	UFUNCTION()
	void DisableKingAndQueen()
	{
		bKingAndQueenDisable = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(CallInEditor, Category = "Chessboard")
	void SpawnTileActors()
	{
		for (auto OldActor : TileActors)
		{
			if (OldActor != nullptr)
			{
				if (OldActor.Checkpoint != nullptr)
				{
					OldActor.Checkpoint.DestroyActor();
					OldActor.Checkpoint = nullptr;
				}

				OldActor.DestroyActor();
			}
		}
		TileActors.Empty();

		// Spawn a tile actor for each tile on the board
		for (int Y = 0; Y < GridSize.Y; ++Y)
		{
			for (int X = 0; X < GridSize.X; ++X)
			{
				AChessTile Tile = Cast<AChessTile>(SpawnActor(TileActorClass.Get()));
				Tile.GridPosition = FVector2D(X, Y);
				Tile.Chessboard = this;
				Tile.bIsBlackSquare = ((X % 2) != 0) != ((Y % 2) != 0);
				Tile.AttachToActor(this);
				Tile.SetActorLocation(GetSquareCenter(Tile.GridPosition));

				Tile.Checkpoint = ACheckpoint::Spawn();
				Tile.Checkpoint.ActorRotation = FRotator::MakeFromX(Tile.ActorRightVector);
				Tile.Checkpoint.ActorLocation = Tile.ActorLocation + (Tile.ActorForwardVector * Tile.Checkpoint.SecondPosition.Location.Size() / 2.f);
				TileActors.Add(Tile);
			}
		}
	}

	// Get the list of all chess piece castle enemies currently on this chessboard
	UFUNCTION(Category = "Chessboard")
	const TArray<ACastleEnemy>& GetAllChessPieces() property
	{
		return AllPieces;
	}

	UFUNCTION()
	AChessTile GetTileActor(FVector2D GridPosition)
	{
		if (!IsGridPositionValid(GridPosition))
			return nullptr;
		return TileActors[GridPosition.Y * GridSize.X + GridPosition.X];
	}

	UFUNCTION()
	float GetTurnDuration() property
	{
		return TurnInterval;
	}

	UFUNCTION(BlueprintPure)
	float GetTurnSpeedMultiplier() property
	{
		return CurrentSpeedMultiplier;
	}

	UFUNCTION()
	void SetTurnSpeedMultiplier(float Multiplier) property
	{
		CurrentSpeedMultiplier = Multiplier;
	}

	UFUNCTION()
	void ResetTurnSpeedMultiplier()
	{
		CurrentSpeedMultiplier = 1.f;
	}

	UFUNCTION(BlueprintPure)
	bool IsSquareOccupied(FVector2D GridPos, AActor IgnoreActor = nullptr)
	{
		AChessTile TileActor = GetTileActor(GridPos);
		if (TileActor == nullptr)
			return false;
		if (TileActor.ActorsOnTile.Num() != 0)
		{
			if (IgnoreActor == nullptr || TileActor.ActorsOnTile.Num() > 1 || TileActor.ActorsOnTile[0] != IgnoreActor)
				return true;
		}
		if (TileActor.bIsDropped)
			return true;
		return false;
	}

	void ActorOccupiesSquare(FVector2D GridPos, AHazeActor Actor)
	{
		ACastleEnemy EnemyActor = Cast<ACastleEnemy>(Actor);
		if (EnemyActor != nullptr)
		{
			if (EnemyActor.bKilled)
				return;
		}

		AChessTile TileActor = GetTileActor(GridPos);
		if (TileActor != nullptr)
			TileActor.ActorsOnTile.AddUnique(Actor);
	}

	void RemoveActorFromSquare(FVector2D GridPos, AHazeActor Actor)
	{
		AChessTile TileActor = GetTileActor(GridPos);
		if (TileActor != nullptr)
			TileActor.ActorsOnTile.Remove(Actor);
	}

	void ChessPieceKilled(ACastleEnemy Enemy)
	{
		for (auto TileActor : TileActors)
			TileActor.ActorsOnTile.Remove(Enemy);
		OnChessPieceKilled.Broadcast(Enemy);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Progress 
		TurnRemainingTime += CurrentSpeedMultiplier * DeltaTime;
		while (TurnRemainingTime >= TurnInterval)
		{
			CurrentTurn += 1;
			OnChessboardTurn.Broadcast(this, CurrentTurn);
			TurnRemainingTime -= TurnInterval;
		}
	}

	// Get the world position for the top left of the grid
	FVector GetTopLeft() property
	{
		FVector Offset;
		Offset.X = -1.f * FMath::FloorToFloat(GridSize.X / 2.f) * SquareSize.X;
		Offset.Y = -1.f * FMath::FloorToFloat(GridSize.Y / 2.f) * SquareSize.Y;

		return ActorTransform.TransformPosition(Offset);
	}

	// Get the world position for the bottom right of the grid
	FVector GetBotRight() property
	{
		FVector Offset;
		Offset.X = FMath::CeilToFloat(GridSize.X / 2.f) * SquareSize.X;
		Offset.Y = FMath::CeilToFloat(GridSize.Y / 2.f) * SquareSize.Y;

		return ActorTransform.TransformPosition(Offset);
	}

	// Get the world position of the center of a grid square
	FVector GetSquareCenter(FVector2D Position)
	{
		FVector Offset;
		Offset.X = (Position.X - FMath::FloorToFloat(GridSize.X / 2.f)) * SquareSize.X;
		Offset.Y = (Position.Y - FMath::FloorToFloat(GridSize.Y / 2.f)) * SquareSize.Y;

		Offset.X += SquareSize.X * 0.5f;
		Offset.Y += SquareSize.Y * 0.5f;

		return ActorTransform.TransformPosition(Offset);
	}

	// Get the grid position this world position (flattened) is in.
	//  Returns false if the world position is outside the grid
	bool GetGridPosition(FVector WorldPosition, FVector2D& OutGridPosition)
	{
		FVector RelativePos = ActorTransform.InverseTransformPosition(WorldPosition);

		OutGridPosition.X = FMath::FloorToFloat(RelativePos.X / SquareSize.X) + FMath::FloorToFloat(GridSize.X / 2.f);
		OutGridPosition.Y = FMath::FloorToFloat(RelativePos.Y / SquareSize.Y) + FMath::FloorToFloat(GridSize.Y / 2.f);

		return IsGridPositionValid(OutGridPosition);
	}

	// Get the closest grid position to a world position (flattened)
	FVector2D GetClosestGridPosition(FVector WorldPosition)
	{
		FVector RelativePos = ActorTransform.InverseTransformPosition(WorldPosition);

		FVector2D GridPos;
		GridPos.X = FMath::FloorToFloat(RelativePos.X / SquareSize.X) + FMath::FloorToFloat(GridSize.X / 2.f);
		GridPos.Y = FMath::FloorToFloat(RelativePos.Y / SquareSize.Y) + FMath::FloorToFloat(GridSize.Y / 2.f);

		GridPos.X = FMath::Clamp(GridPos.X, 0, GridSize.X - 1);
		GridPos.Y = FMath::Clamp(GridPos.Y, 0, GridSize.Y - 1);
		return GridPos;
	}

	// Check whether a grid position is inside the grid
	UFUNCTION(BlueprintPure)
	bool IsGridPositionValid(FVector2D GridPos)
	{
		return GridPos.X >= 0 && GridPos.Y >= 0
			&& GridPos.X < GridSize.X && GridPos.Y < GridSize.Y;
	}

	// Get the direction vector for the board's X grid
	FVector GetXVector() property
	{
		return ActorTransform.TransformVector(FVector(1.f, 0.f, 0.f));
	}

	// Get the direction vector for the board's Y grid
	FVector GetYVector() property
	{
		return ActorTransform.TransformVector(FVector(0.f, 1.f, 0.f));
	}

	TArray<AHazePlayerCharacter> GetPlayersOnSquare(FVector2D GridPos, float HeightMargin = 300.f)
	{
		TArray<AHazePlayerCharacter> OutPlayers;
		for(auto Player : Game::GetPlayers())
		{
			FVector2D PlayerPos;
			if (!GetGridPosition(Player.ActorLocation, PlayerPos))
				continue;
			if (PlayerPos != GridPos)
				continue;
			if (FMath::Abs(Player.ActorLocation.Z - ActorLocation.Z) > HeightMargin)
				continue;
			OutPlayers.Add(Player);
		}
		return OutPlayers;
	}

    ACastleEnemy SpawnChessPiece(TSubclassOf<ACastleEnemy> EnemyToSpawn, FVector2D GridPosition)
    {
        if (!EnemyToSpawn.IsValid())
        {
            devEnsure(false, "Invalid enemy class on chessboard spawn.");
            return nullptr;
        }

		FVector EnemyLocation = GetSquareCenter(GridPosition);

        auto Enemy = Cast<ACastleEnemy>(SpawnActor(EnemyToSpawn, EnemyLocation, bDeferredSpawn = true));
        Enemy.MakeNetworked(this, EnemiesSpawned);
		FinishSpawningActor(Enemy);
        EnemiesSpawned += 1;
        return Enemy;
    }

	TArray<FVector2D> GetSurroundingTileLocations(FVector2D CenterTileLocation, bool bIncludeCenter = false)
	{
		TArray<FVector2D> TilesAroundTile;
		if (bIncludeCenter)
			TilesAroundTile.Add(CenterTileLocation);
		TilesAroundTile.Add(CenterTileLocation + FVector2D(1, 0));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(1, 1));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(0, 1));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(-1, 1));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(-1, 0));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(-1, -1));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(0, -1));
		TilesAroundTile.Add(CenterTileLocation + FVector2D(1, -1));
	
		return TilesAroundTile;
	}

	TArray<FVector2D> GetTilesInLine(FVector2D StartTileLocation, FVector2D EndTileLocation, bool bIncludeStart = false, bool bIncludeEnd = true)
	{
		FVector2D DeltaMove = EndTileLocation - StartTileLocation;
		FVector2D Direction = FVector2D(FMath::Sign(DeltaMove.X), FMath::Sign(DeltaMove.Y));
		int Distance = FMath::Max(FMath::Abs(DeltaMove.X), FMath::Abs(DeltaMove.Y));

		TArray<FVector2D> TilesInLine;		

		for (int Index = 0, Count = Distance; Index <= Count; Index++)
		{
			if (Index == 0 && !bIncludeStart)
				continue;

			if (Index == Count && !bIncludeEnd)
				continue;			

			FVector2D TileLocation = StartTileLocation + (Direction * Index);
			TilesInLine.Add(TileLocation);
		}

		return TilesInLine;
	}

	FVector2D GetChessDirectionFromDirection(FVector2D InDirection)
	{
		FVector2D Direction = InDirection.GetSafeNormal();
		
		if (FMath::Abs(Direction.X) >= 0.5f)
			Direction.X = FMath::Sign(Direction.X);
		else 
			Direction.X = 0.f;

		if (FMath::Abs(Direction.Y) >= 0.5f)
			Direction.Y = FMath::Sign(Direction.Y);
		else 
			Direction.Y = 0.f;

		return Direction;
	}
};

class AChessTile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TileMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TileMeshRoot)
	UStaticMeshComponent TileMesh;

	UPROPERTY(DefaultComponent, Attach = TileMesh)
	UDecalComponent TelegraphShadow;

	UPROPERTY(EditConst, BlueprintReadOnly)
	AChessboard Chessboard;

	UPROPERTY(EditConst, BlueprintReadOnly)
	FVector2D GridPosition;

	UPROPERTY(EditConst, BlueprintReadOnly)
	bool bIsBlackSquare = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsDropped = false;

	TArray<AHazeActor> ActorsOnTile;

	UPROPERTY()
	ACheckpoint Checkpoint;

	float CurrentTelegraphDuration = 0.f;

	// Tile rook tremble
	bool bShouldTremble = false;
	FVector TrembleTileOffset;
	float TrembleTimeOffset;
	float TrembleSpeed = 30.f;
	UPROPERTY()
	bool bShowHorizontalLights;
	UPROPERTY()
	bool bShowVerticalLights;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BP_Initialize();		
		
		EnableCheckpoint();

		TrembleTimeOffset = FMath::RandRange(-1.f , 1.f);
	}

	void EnableCheckpoint()
	{
		if (Checkpoint != nullptr)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				Checkpoint.EnableForPlayer(Player);
			}
		}
	}

	void DisableCheckpoint()
	{
		if (Checkpoint != nullptr)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				Checkpoint.DisableForPlayer(Player);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateTelegraphDuration(DeltaTime);

		if (bShouldTremble)
		{	
			// float TrembleScale = 12.f;
			// TrembleTileOffset = FVector::ZeroVector;
			// TrembleTileOffset.Z = FMath::Sin((TrembleTimeOffset + Time::GameTimeSeconds) * TrembleSpeed);
			// TrembleTileOffset.Z += 1.f;
			// TrembleTileOffset.Z /= 2.f;
			// TrembleTileOffset.Z *= TrembleScale;

			// TileMesh.SetVectorParameterValueOnMaterials(n"WorldOffset", TrembleTileOffset);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Initialize() {}

	UFUNCTION()
	void DropTile(float LoweredDuration = 4.f)
	{
		if (Chessboard.bChessboardDisabled)
			return;
		bIsDropped = true;
		
		StopTremble();
		DisableCheckpoint();
		BP_DropTile(LoweredDuration);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DropTile(float LoweredDuration) {}

	UFUNCTION()
	void RestoreTile()
	{
		bIsDropped = false;		
		EnableCheckpoint();
		BP_RestoreTile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RestoreTile() {}

	UFUNCTION()
	void SnapToTop()
	{
		if (bIsDropped)
		{
			bIsDropped = false;
			BP_SnapToTop();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapToTop() {}

	UFUNCTION(BlueprintEvent)
	void StartTremble()
	{
		bShouldTremble = true;
	}

	UFUNCTION(BlueprintEvent)
	void StopTremble()
	{
		bShouldTremble = false;
		bShowVerticalLights = false;
		bShowHorizontalLights = false;
		TrembleTileOffset = FVector::ZeroVector;
		TileMesh.SetVectorParameterValueOnMaterials(n"WorldOffset", TrembleTileOffset);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void TelegraphTile(float OverrideTelegraphDuration = -1.f)
	{
		if (OverrideTelegraphDuration > 0.f)
			CurrentTelegraphDuration = OverrideTelegraphDuration;
		else
			CurrentTelegraphDuration = Chessboard.TelegraphDuration;

		TelegraphShadow.SetVisibility(true);	 
	}

	void UpdateTelegraphDuration(float DeltaTime)
	{
		if (CurrentTelegraphDuration > 0.f)
			CurrentTelegraphDuration -= DeltaTime;

		if (CurrentTelegraphDuration <= 0.f)
			TelegraphShadow.SetVisibility(false);
	}
}

struct FTileSquareGroupTimer
{
	FTileSquareGroupTimer(TArray<FVector2D> InTileCoordinates, float InDuration = 0.f)
	{
		TileCoordinates = InTileCoordinates;
		Duration = InDuration;
	}

	UPROPERTY()
	TArray<FVector2D> TileCoordinates;

	UPROPERTY()
	float Duration = 0.f;
}

struct FTileSquareTimer
{
	FTileSquareTimer(FVector2D InTileCoorinate, float InDuration = 0.f)
	{
		TileCoordinate = InTileCoorinate;
		Duration = InDuration;
	}

	UPROPERTY()
	FVector2D TileCoordinate;

	UPROPERTY()
	float Duration = 0.f;
}