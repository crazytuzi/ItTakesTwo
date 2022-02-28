import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

/* Jump a spectating chess piece into the fight at a specific grid square. */
UFUNCTION(Category = "Castle Enemy Chess Piece")
void JumpInChessPieceToGridSquare(AChessboard Chessboard, ACastleEnemy Enemy, FVector2D GridSquare, float JumpHeight = 600.f, float JumpDuration = 0.8f)
{
	FVector WorldPos = Chessboard.GetSquareCenter(GridSquare);
	JumpInChessPieceToWorldPosition(Chessboard, Enemy, WorldPos, JumpHeight, JumpDuration);
}

/* Jump a spectating chess piece into the fight at a specific world position. */
UFUNCTION(Category = "Castle Enemy Chess Piece")
void JumpInChessPieceToWorldPosition(AChessboard Chessboard, ACastleEnemy Enemy, FVector WorldPosition, float JumpHeight = 600.f, float JumpDuration = 0.8f, EChessPieceState StateAfterJump = EChessPieceState::Fighting)
{
	auto PieceComp = UChessPieceComponent::GetOrCreate(Enemy);
	// if(!ensure(PieceComp.State == EChessPieceState::Spectating))
	// 	return;

	PieceComp.JumpIntoFight(Chessboard, WorldPosition, JumpHeight, JumpDuration, StateAfterJump);
}


/* Teleport a chess piece into the fight at a specific grid square. */
UFUNCTION(Category = "Castle Enemy Chess Piece")
void TeleportChessPieceToGridSquare(AChessboard Chessboard, ACastleEnemy Enemy, FVector2D GridSquare)
{
	FVector WorldPos = Chessboard.GetSquareCenter(GridSquare);
	TeleportChessPieceToWorldPosition(Chessboard, Enemy, WorldPos);
}

/* Teleport a chess piece into the fight at a specific World Position. */
UFUNCTION(Category = "Castle Enemy Chess Piece")
void TeleportChessPieceToWorldPosition(AChessboard Chessboard, ACastleEnemy Enemy, FVector WorldPosition)
{
	auto PieceComp = UChessPieceComponent::GetOrCreate(Enemy);
	PieceComp.TeleportIntoFight(Chessboard, WorldPosition);
}


/* Update the chess pieces state */
UFUNCTION()
void SetChessPieceState(AHazeActor ChessPiece, EChessPieceState NewState = EChessPieceState::Fighting)
{
	if (ChessPiece == nullptr)
		return;

	UChessPieceComponent ChessPieceComp = UChessPieceComponent::GetOrCreate(ChessPiece);
	if (ChessPieceComp == nullptr)
		return;
	
	ChessPieceComp.State = NewState;
}