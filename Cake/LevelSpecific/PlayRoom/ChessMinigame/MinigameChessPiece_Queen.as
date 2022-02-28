import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoves;

UCLASS(Abstract)
class AMinigameChessPieceQueen : AMinigameChessPieceBase
{
	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override
	{
		for(int X = -1; X < 2; X++)
		{
			for(int Y = -1; Y < 2; Y++)
			{		
				if(X == 0 && Y == 0)
					continue;

				// We search from the piece to the valid directions
				FChessMinigamePosition CurrentPosition = GetBoardPosition();
				bool bContinueSearch = false;
				do
				{
					CurrentPosition = CurrentPosition.OffsetWith(X, Y);
					EChessMinigamePieceMovePosition EvaluationPosition(Board, CurrentPosition);
					EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
					bContinueSearch = EvaluationPosition.MoveType == EChessMinigamePieceMoveType::Available;
					AddSearchResult(this, EvaluationPosition, OutMoves);

					// We have found the king so no need to search more
					if(OutMoves.HasAnyMoves() && OutMoves.bBreakAtFirstFind)
					{
						return;
					}
						

				} while(bContinueSearch);
			}
		}
		
	}
}