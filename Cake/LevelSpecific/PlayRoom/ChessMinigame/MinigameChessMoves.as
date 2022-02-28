import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;

void EvaluatePosition(
	AMinigameChessPieceBase FromPiece, 
	EChessMinigamePieceMoveSearchType SearchFilter,
	EChessMinigamePieceMovePosition& OutPosition
	)
{
	if(FromPiece == nullptr)
	{
		OutPosition.MoveType = EChessMinigamePieceMoveType::Invalid;
		return;
	}
	
	auto Board = FromPiece.Board;
	auto Tile = OutPosition.Tile;
	
	// Outside board
	if(Tile == nullptr)
	{
		OutPosition.MoveType = EChessMinigamePieceMoveType::Invalid;
		return;
	}
		
	// Can we move here
	if(SearchFilter == EChessMinigamePieceMoveSearchType::PreviewMove)
	{
		// Something is blocking this
		if(Tile.Piece != nullptr)
		{
			// We can fight this
			if(FromPiece.IsOppositeTeam(Tile.Piece))
			{
				OutPosition.MoveType = EChessMinigamePieceMoveType::Combat;
				OutPosition.MoveTypeInstigator = Tile.Piece;
				if(Tile.Piece.IsKing())
					OutPosition.SubType = EChessMinigamePieceMoveSubType::King;	
				return;			
			}

			OutPosition.MoveType = EChessMinigamePieceMoveType::Blocked;
			return;
		}
		else
		{
			OutPosition.MoveType = EChessMinigamePieceMoveType::Available;
			return;
		}
	}
	// Will the king be exposed if the current selected pieces moves here
	else if(SearchFilter == EChessMinigamePieceMoveSearchType::CanReachEnemyKing)
	{
		// We have hit the current preview piece
		AMinigameChessPieceBase FoundPiece = Tile.PreviewPiece;
		if(FoundPiece == nullptr)
			FoundPiece = Tile.Piece;

		if(FoundPiece != nullptr)
		{
			if(FromPiece.IsOppositeTeam(FoundPiece) && FoundPiece.IsKing())
			{
				OutPosition.MoveType = EChessMinigamePieceMoveType::Combat;
				OutPosition.SubType = EChessMinigamePieceMoveSubType::King;
				OutPosition.MoveTypeInstigator = FoundPiece;
			}
			else
			{
				OutPosition.MoveType = EChessMinigamePieceMoveType::Blocked;
			}	
		}
		else
		{
			OutPosition.MoveType = EChessMinigamePieceMoveType::Available;
		}
		return;
	}
}

void AddSearchResult(
	AMinigameChessPieceBase FromPiece, 
	EChessMinigamePieceMovePosition Position, 
	EChessMinigamePieceMovePositionArray& OutMoves)
{
	if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::PreviewMove)
	{
		if(Position.IsMovableMove())
			OutMoves.Add(Position);
		else if(Position.IsBlockedMove())
			OutMoves.Add(Position);
	}
	else if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::CanReachEnemyKing)
	{
		if(Position.MoveType == EChessMinigamePieceMoveType::Combat)
			OutMoves.Add(Position);
	}
}
