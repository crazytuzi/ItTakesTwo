import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

event void FOnChessPieceMoveStarted(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D DestinationGridPosition);
event void FOnChessPieceTelegraphDone(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D DestinationGridPosition);
event void FOnChessPieceLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D NewGridPosition);
event void FOnChessPieceJumpIn(ACastleEnemy Enemy, AChessboard Chessboard, FVector WorldPosition, float JumpHeight, float JumpDuration, EChessPieceState StateAfterJump = EChessPieceState::Fighting);
event void FOnChessPieceAudioAttack();
event void FOnChessPieceAudioDespawn();

enum EChessPieceState
{
	Spectating,
	JumpingIn,
	Fighting
};

enum EChessPieceOrientation
{
	Up,
	Down,
	Left,
	Right
};

FVector2D ModifyGridMovementForDirection(FVector2D Movement, EChessPieceOrientation Orientation, bool bMirror = false)
{
	int MirrorDir = bMirror ? -1 : 1;
	switch(Orientation)
	{
		case EChessPieceOrientation::Up: return FVector2D(Movement.X * MirrorDir, Movement.Y);
		case EChessPieceOrientation::Down: return FVector2D(Movement.X * MirrorDir, -Movement.Y);
		case EChessPieceOrientation::Left: return FVector2D(Movement.Y, Movement.X * MirrorDir);
		case EChessPieceOrientation::Right: return FVector2D(-Movement.Y, Movement.X * MirrorDir);
	}
	return Movement;
}

class UChessPieceComponent : UActorComponent
{
	UPROPERTY()
	AChessboard Chessboard;
	UPROPERTY()
	FVector2D GridPosition;
	FVector2D CurrentDestination;

	// Start delay before the piece starts moving the first time, in chessboard turns
	UPROPERTY(EditAnywhere)
	int StartDelayTurns = 5;

	// Initial state for the chess piece as placed
	UPROPERTY(EditAnywhere)
	EChessPieceState State = EChessPieceState::Fighting;

	// Orientation for the chess piece as placed
	UPROPERTY(EditAnywhere)
	EChessPieceOrientation Orientation = EChessPieceOrientation::Up;

	// Whether to mirror the orientation (useful for knights)
	UPROPERTY(EditAnywhere)
	bool bMirrorOrientation = false;

	UPROPERTY()
	FOnChessPieceMoveStarted OnMoveStarted;

	UPROPERTY()
	FOnChessPieceLanded OnLanded;

	UPROPERTY()
	FOnChessPieceTelegraphDone OnTelegraphDone;

	UPROPERTY()
	FOnChessPieceJumpIn OnJumpIn;

	UPROPERTY()
	FOnChessPieceAudioAttack OnChessPieceAttack;

	UPROPERTY()
	FOnChessPieceAudioDespawn OnChessPieceDespawn;

	UPROPERTY()
	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AChessboard> Boards;
		GetAllActorsOfClass(Boards);

		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(Owner);
		CastleEnemy.OnKilled.AddUFunction(this, n"OnOwnerKilled");

		for(auto Board : Boards)
		{
			if (Board.GetGridPosition(Owner.ActorLocation, GridPosition))
			{
				Chessboard = Board;
				Chessboard.AllPieces.AddUnique(Cast<ACastleEnemy>(Owner));
				Board.ActorOccupiesSquare(GridPosition, Cast<AHazeActor>(Owner));
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (Chessboard != nullptr)
			Chessboard.AllPieces.Remove(Cast<ACastleEnemy>(Owner));
	}

	UFUNCTION()
	void OnOwnerKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		if (Chessboard == nullptr)
			return;

		Chessboard.AllPieces.Remove(Enemy);
		Chessboard.ChessPieceKilled(Enemy);
	}

	void StartMoving(FVector2D DestinationPosition)
	{
		CurrentDestination = DestinationPosition;
		OnMoveStarted.Broadcast(Cast<ACastleEnemy>(Owner), Chessboard, GridPosition, CurrentDestination);
		bIsMoving = true;		
	}

	void TelegraphDone(FVector2D DestinationPosition)
	{
		OnTelegraphDone.Broadcast(Cast<ACastleEnemy>(Owner), Chessboard, GridPosition, DestinationPosition);
	}

	void LandOnPosition(FVector2D NewPosition)
	{
		FVector2D OldPosition = GridPosition;
		Chessboard.RemoveActorFromSquare(GridPosition, Cast<AHazeActor>(Owner));
		Chessboard.ActorOccupiesSquare(NewPosition, Cast<AHazeActor>(Owner));

		GridPosition = NewPosition;
		OnLanded.Broadcast(Cast<ACastleEnemy>(Owner), Chessboard, OldPosition, NewPosition);
		bIsMoving = false;
	}

	void JumpIntoFight(AChessboard InChessboard, FVector WorldPosition, float JumpHeight, float JumpDuration, EChessPieceState InStateAfterJump = EChessPieceState::Fighting)
	{
		Chessboard = InChessboard;
		Chessboard.AllPieces.AddUnique(Cast<ACastleEnemy>(Owner));

		GridPosition = Chessboard.GetClosestGridPosition(WorldPosition);
		Chessboard.ActorOccupiesSquare(GridPosition, Cast<AHazeActor>(Owner));

		OnJumpIn.Broadcast(Cast<ACastleEnemy>(Owner), Chessboard, WorldPosition, JumpHeight, JumpDuration, InStateAfterJump);
	}

	void TeleportIntoFight(AChessboard InChessboard, FVector WorldPosition)
	{
		Chessboard = InChessboard;
		Chessboard.AllPieces.AddUnique(Cast<ACastleEnemy>(Owner));

		Owner.SetActorLocation(WorldPosition);

		GridPosition = Chessboard.GetClosestGridPosition(WorldPosition);
		Chessboard.ActorOccupiesSquare(GridPosition, Cast<AHazeActor>(Owner));
	}


	FVector2D ModifyGridMovementForOrientation(FVector2D Movement)
	{
		return ModifyGridMovementForDirection(Movement, Orientation, bMirrorOrientation);
	}

	UFUNCTION(BlueprintPure)
	FVector2D GetGridPositionAfterMovement(FVector2D Movement, bool bIsReversed)
	{
		return GridPosition + ModifyGridMovementForOrientation(Movement) * (bIsReversed ? -1.f : 1.f);
	}

	FVector2D GetRandomCoordinate() property
	{
		int X = FMath::RandRange(0, FMath::FloorToInt(Chessboard.GridSize.X));
		int Y = FMath::RandRange(0, FMath::FloorToInt(Chessboard.GridSize.Y));

		return FVector2D(X, Y);
	}
};

struct FChessTileTimer
{
	UPROPERTY()
	AChessTile Tile;

	UPROPERTY()
	float Duration = 0.f;
}