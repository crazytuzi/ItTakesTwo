import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoves;

UCLASS(Abstract)
class AMinigameChessPieceRook : AMinigameChessPieceBase
{
	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override
	{
		for(int X = -1; X < 2; X += 2)
		{
			if(X == 0)
				continue;

			// We search from the piece to the valid directions
			FChessMinigamePosition CurrentPosition = GetBoardPosition();
			bool bContinueSearch = false;
			do
			{
				CurrentPosition = CurrentPosition.OffsetWith(X, 0);
				EChessMinigamePieceMovePosition EvaluationPosition(Board, CurrentPosition);
				EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
				bContinueSearch = EvaluationPosition.MoveType == EChessMinigamePieceMoveType::Available;
				AddSearchResult(this, EvaluationPosition, OutMoves);

				// We have found the king so no need to search more
				if(OutMoves.HasAnyMoves() && OutMoves.bBreakAtFirstFind)
					return;

			} while(bContinueSearch);
		}

		for(int Y = -1; Y < 2; Y += 2)
		{
			if(Y == 0)
				continue;

			// We search from the piece to the valid directions
			FChessMinigamePosition CurrentPosition = GetBoardPosition();
			bool bContinueSearch = false;
			do
			{
				CurrentPosition = CurrentPosition.OffsetWith(0, Y);
				EChessMinigamePieceMovePosition EvaluationPosition(Board, CurrentPosition);
				EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
				bContinueSearch = EvaluationPosition.MoveType == EChessMinigamePieceMoveType::Available;
				AddSearchResult(this, EvaluationPosition, OutMoves);

				// We have found the king so no need to search more
				if(OutMoves.HasAnyMoves() && OutMoves.bBreakAtFirstFind)
					return;

			} while(bContinueSearch);
		}
	}

	void PlayerInitializedMovement(AHazePlayerCharacter Player,  EChessMinigamePieceMovePosition Position) override
	{
		if(Position.MoveType == EChessMinigamePieceMoveType::Castling)
		{
			DeactivatePreview(Player);

			auto MyKing = Board.GetKing(bIsBlack);
			_State = EMinigameChessPieceState::PieceMovingToTile;
			ActiveMoveToPosition = Position;

			ActiveMoveTo.InitializeMove(
			GetActorLocation(),
			Board.GetWorldPosition(Position.Tile),
			MyKing.Collision.CapsuleHalfHeight * 2,
			JumpMove);
		}
		else
		{
			Super::PlayerInitializedMovement(Player, Position);
		}
	}
}