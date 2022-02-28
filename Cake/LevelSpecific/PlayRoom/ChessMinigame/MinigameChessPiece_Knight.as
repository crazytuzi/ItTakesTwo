import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoves;


UCLASS(Abstract)
class AMinigameChessPieceKnight : AMinigameChessPieceBase
{
	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override
	{
		int MoveDir = bIsBlack ? -1 : 1;
		const FChessMinigamePosition CurrentPosition = GetBoardPosition();
		
		TArray<FChessMinigamePosition> PotentialMoves;

		PotentialMoves.Add(CurrentPosition.OffsetWith(1, MoveDir * 2));
		PotentialMoves.Add(CurrentPosition.OffsetWith(-1, MoveDir * 2));
		PotentialMoves.Add(CurrentPosition.OffsetWith(1, -MoveDir * 2));
		PotentialMoves.Add(CurrentPosition.OffsetWith(-1, -MoveDir * 2));

		PotentialMoves.Add(CurrentPosition.OffsetWith(2, MoveDir));
		PotentialMoves.Add(CurrentPosition.OffsetWith(-2, MoveDir));
		PotentialMoves.Add(CurrentPosition.OffsetWith(2, -MoveDir));
		PotentialMoves.Add(CurrentPosition.OffsetWith(-2, -MoveDir));

		for(int i = 0; i < PotentialMoves.Num(); ++i)
		{
			EChessMinigamePieceMovePosition EvaluationPosition(Board, PotentialMoves[i]);
			EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
			AddSearchResult(this, EvaluationPosition, OutMoves);

			// We have found the king so no need to search more
			if(OutMoves.HasAnyMoves() && OutMoves.bBreakAtFirstFind)
				return;
		}
	}
}