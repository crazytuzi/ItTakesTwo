import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoves;


UCLASS(Abstract)
class AMinigameChessPiecePawn : AMinigameChessPieceBase
{
	float DelayTimeLeftToNextJumpAfterEnpassant = 0;

	void PlayerInitializedMovement(AHazePlayerCharacter Player, EChessMinigamePieceMovePosition Position) override
	{
		Super::PlayerInitializedMovement(Player, Position);
	
		// We first jump to the instigator piece position
		if(Position.IsMoveEnpassant())
		{
			auto FirstJumpTile = Position.MoveTypeInstigator.GetBoardTile();
			ActiveMoveTo.InitializeMove(
				GetActorLocation(),
				Board.GetWorldPosition(FirstJumpTile),
				Collision.GetCapsuleHalfHeight() * 2,
				JumpMove);

		}
	}

	bool UpdateMoveTo(float DeltaTime) override
	{
		// We make a small delay to the next move to make it look better
		if(DelayTimeLeftToNextJumpAfterEnpassant > 0)
		{
			DelayTimeLeftToNextJumpAfterEnpassant -= DeltaTime;
			if(DelayTimeLeftToNextJumpAfterEnpassant <= 0)
			{
				_State = EMinigameChessPieceState::PieceMovingToTile;
				ActiveMoveTo.InitializeMove(
					GetActorLocation(),
					Board.GetWorldPosition(ActiveMoveToPosition.Tile),
					Collision.GetCapsuleHalfHeight() * 0.75f,
					JumpMove);

				ActiveMoveTo.LandingTime *= 0.75f;
			}

			return true;
		}	

		if(Super::UpdateMoveTo(DeltaTime))
			return true;
		
		if(!ActiveMoveToPosition.IsMoveEnpassant())
			return false;
		
		// Firs clear out the sub type so we dont end up here again
		ActiveMoveToPosition.SubType = EChessMinigamePieceMoveSubType::Unset;
		AMinigameChessPieceBase EnemyPiece = ActiveMoveToPosition.MoveTypeInstigator;
		ActiveMoveToPosition.MoveTypeInstigator = nullptr;

		Board.LastPieceTakenType = EnemyPiece.Type;
		Board.RemovePiece(EnemyPiece);
		
		// Effect
		if(LandedEffect != nullptr)
			Niagara::SpawnSystemAtLocation(LandedEffect, GetActorLocation(), GetActorRotation());

		DelayTimeLeftToNextJumpAfterEnpassant = 0.4f;	
		return true;
	}

	void OnMoveFinalized(AHazePlayerCharacter Player, EChessMinigamePieceMovePosition GridPosition) override
	{
		Super::OnMoveFinalized(Player, GridPosition);

		// If the last move is a long move, we make 'En passant' available
		if(LastMoveSubType == EChessMinigamePieceMoveSubType::Long)
		{
			Board.EnpassantMove = GridPosition;
		}
	}

	void FinalizeMoveState(EChessMinigamePieceMovePosition GridPosition) override
	{
		// At the end of the board; the pawn can become any other piece
		if(IsAtEndTile(GridPosition))
		{
			OnMoveFinalizedInternal();	
			_State = EMinigameChessPieceState::PieceLandedOnSwapPieceTile;					
		}
		else
		{
			Super::FinalizeMoveState(GridPosition);
		}
	}

	bool IsAtEndTile(EChessMinigamePieceMovePosition GridPosition) const
	{
		if(!bIsBlack && GridPosition.BoardPosition.Y == 8)
			return true;
		else if(bIsBlack && GridPosition.BoardPosition.Y == 1)
			return true;
		else
			return false;
	}

	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override
	{
		// This piece cant reach the other king if a piece moves
		if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::CanReachEnemyKing
			&& OutMoves.InstigatorPiece.Type != EChessMinigamePiece::King)
			return;

		const int MoveDir = bIsBlack ? -1 : 1;
		const FChessMinigamePosition CurrentPosition = GetBoardPosition();
		
		TArray<FChessMinigamePosition> PotentialMoves;
		PotentialMoves.Add(CurrentPosition.OffsetWith(0, MoveDir));

		// First time, we can move 2 tiles
		if(!HasMoved())
		{
			PotentialMoves.Add(CurrentPosition.OffsetWith(0, MoveDir * 2));
		}

		bool bContinueSearch = true;
		for(int i = 0; i < PotentialMoves.Num() && bContinueSearch; ++i)
		{
			{
				EChessMinigamePieceMovePosition EvaluationPosition(Board, PotentialMoves[i]);
				EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
				bContinueSearch = EvaluationPosition.MoveType == EChessMinigamePieceMoveType::Available;
				if(i == 1)
					EvaluationPosition.SubType = EChessMinigamePieceMoveSubType::Long;

				// The pawn cant attack straight ahead...
				if(EvaluationPosition.MoveType == EChessMinigamePieceMoveType::Combat)
					EvaluationPosition.MoveType = EChessMinigamePieceMoveType::Blocked;

				AddSearchResult(this, EvaluationPosition, OutMoves);
			}
		}

		// We can pass pawns doing long move called 'EnPassant'
		// First we check if we have a pawn to the side of us, that has made a long move
		// The we check if the move ahead of that is free
		if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::PreviewMove
			&& Board.EnpassantMove.IsValid())
		{
			for(int i = -1; i < 2; i += 2)
			{
				EChessMinigamePieceMovePosition EnPassantMove(Board, CurrentPosition.OffsetWith(i, 0));
				if(EnPassantMove.Tile == Board.EnpassantMove.Tile)
				{
					EnPassantMove = EChessMinigamePieceMovePosition(Board, CurrentPosition.OffsetWith(i, MoveDir));
					EnPassantMove.MoveType = EChessMinigamePieceMoveType::Combat;
					EnPassantMove.SubType = EChessMinigamePieceMoveSubType::Pass;
					EnPassantMove.MoveTypeInstigator = Board.EnpassantMove.Tile.Piece;
					AddSearchResult(this, EnPassantMove, OutMoves);
					break;
				}
			}
		}
		
		// We can attack diagonaly
		{
			TArray<FChessMinigamePosition> PotentialAttackMoves;
			PotentialAttackMoves.Add(CurrentPosition.OffsetWith(-1, MoveDir));
			PotentialAttackMoves.Add(CurrentPosition.OffsetWith(1, MoveDir));

			for(int i = 0; i < PotentialAttackMoves.Num(); ++i)
			{
				EChessMinigamePieceMovePosition AttackEvaluationPosition(Board, PotentialAttackMoves[i]);
				EvaluatePosition(this, OutMoves.SearchFilter, AttackEvaluationPosition);
				if(AttackEvaluationPosition.MoveType == EChessMinigamePieceMoveType::Combat)
					AddSearchResult(this, AttackEvaluationPosition, OutMoves);
			}
		}
	}
}