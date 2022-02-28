import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPiece_Rook;

import void SetActiveChessPiece(AHazePlayerCharacter, AMinigameChessPieceBase) from "Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPlayer";
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoves;

UCLASS(Abstract)
class AMinigameChessPieceKing : AMinigameChessPieceBase
{
	private TArray<EChessMinigamePieceMovePosition> ExposedPositions;
	uint LastGeneratedExposedPositionFrame = 0;

	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override
	{
		// This piece cant reach the other king if a piece moves
		if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::CanReachEnemyKing
			&& OutMoves.InstigatorPiece.Type != EChessMinigamePiece::King)
			return;

		for(int X = -1; X < 2; X++)
		{
			for(int Y = -1; Y < 2; Y++)
			{
				// This is not a valid search direction
				if(X == 0 && Y == 0)
					continue;

				FChessMinigamePosition CurrentPosition = GetBoardPosition();
				CurrentPosition = CurrentPosition.OffsetWith(X, Y);
				EChessMinigamePieceMovePosition EvaluationPosition(Board, CurrentPosition);
				EvaluatePosition(this, OutMoves.SearchFilter, EvaluationPosition);
				AddSearchResult(this, EvaluationPosition, OutMoves);

				// We have found the king so no need to search more
				if(OutMoves.HasAnyMoves() && OutMoves.bBreakAtFirstFind)
					return;
			}
		}

		if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::PreviewMove)
		{
			// Evaluate Castling
			if(!HasMoved())
			{		
				// Long
				{
					const int LongCastleMove = -4;
					if(EvaluateCastling(LongCastleMove))
					{
						auto JumpToTile = Board.GetTileActor(GetBoardPosition().OffsetWith(-2, 0));
						EChessMinigamePieceMovePosition CastleMove(JumpToTile, EChessMinigamePieceMoveType::Castling);
						CastleMove.SubType = EChessMinigamePieceMoveSubType::Long;
						OutMoves.Add(CastleMove);
					}
				}

				// Short
				{
					const int ShortCastleMove = 3;
					if(EvaluateCastling(ShortCastleMove))
					{
						auto JumpToTile = Board.GetTileActor(GetBoardPosition().OffsetWith(2, 0));
						EChessMinigamePieceMovePosition CastleMove(JumpToTile, EChessMinigamePieceMoveType::Castling);
						CastleMove.SubType = EChessMinigamePieceMoveSubType::Short;
						OutMoves.Add(CastleMove);
					}
				}
			}
		}	
	}

	void FinalizeAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves) override 
	{
		// The king needs to validate that it would not get checked moving to these positions
		if(OutMoves.SearchFilter == EChessMinigamePieceMoveSearchType::PreviewMove)
		{
			const uint FrameNumber = Time::GetFrameNumber();
			if(FrameNumber > LastGeneratedExposedPositionFrame)
			{
				ExposedPositions.SetNum(0);
				LastGeneratedExposedPositionFrame = FrameNumber;
			}

			// We preplace the king at the current wanted location and see what happens
			const TArray<EChessMinigamePieceMovePosition> AvailableMoves = OutMoves.CollectedMoves;
			OutMoves.CollectedMoves.Reset(AvailableMoves.Num());

			for(EChessMinigamePieceMovePosition Move : AvailableMoves)
			{
				if(Move.IsBlockedMove())
				{
					// Blocked moves will just show the gui
					OutMoves.CollectedMoves.Add(Move);
					continue;
				}

				// This might not be the king, we always come in here no mather what piece is moving
				OutMoves.InstigatorPiece.SetPreviewMoveTile(Move.Tile);

				EChessMinigamePieceMovePositionArray PotentialEnemyMoves = EChessMinigamePieceMovePositionArray(this);
				PotentialEnemyMoves.SearchFilter = EChessMinigamePieceMoveSearchType::CanReachEnemyKing;
			
				AMinigameChessPieceBase Attacker = nullptr;
				const auto& OtherTeam = bIsBlack ? Board.WhiteTeam : Board.BlackTeam;
				for(auto Piece : OtherTeam)
				{
					// If this move is where we kill this piece, this is ignored
					if(Move.IsCombatMove() && Move.GetBoardPosition().IsEqual(Piece.GetBoardPosition()))
						continue;

					PotentialEnemyMoves.CollectedMoves.Reset(1);
					Piece.GetAvailableMoves(PotentialEnemyMoves);
					for(EChessMinigamePieceMovePosition AttackerMove : PotentialEnemyMoves.CollectedMoves)
					{	
						Attacker = Piece;
						break;
					}

					if(Attacker != nullptr)
						break;
				}

				OutMoves.InstigatorPiece.SetPreviewMoveTile(nullptr);
	
				if(Attacker == nullptr)
				{
					// This here is free to move to
					OutMoves.CollectedMoves.Add(Move);
				}
				else
				{
					// We cant move here since that will check the king
					EChessMinigamePieceMovePosition CkeckedMove = Move;
					CkeckedMove.MoveType = EChessMinigamePieceMoveType::Available;
					CkeckedMove.SubType = EChessMinigamePieceMoveSubType::Exposed;
					CkeckedMove.MoveTypeInstigator = Attacker;
					ExposedPositions.Add(CkeckedMove);
					OutMoves.CollectedMoves.Add(CkeckedMove);
				}
			}
		}
	}

	void OnMoveFinalized(AHazePlayerCharacter Player, EChessMinigamePieceMovePosition GridPosition) override
	{
		Super::OnMoveFinalized(Player, GridPosition);

		// We are doing castling with a rook
		if(GridPosition.MoveType == EChessMinigamePieceMoveType::Castling)
		{
			ActivateCastling(Player, GetBoardPosition(), GridPosition.SubType);		
		}
	}

	void ActivateCastling(AHazePlayerCharacter Player, FChessMinigamePosition KingPosition, EChessMinigamePieceMoveSubType Type)
	{
		FChessMinigamePosition RookPosition;
		FChessMinigamePosition RookMoveToPosition;
		if(Type == EChessMinigamePieceMoveSubType::Short)
		{
			RookPosition = KingPosition.OffsetWith(1, 0);
			RookMoveToPosition = KingPosition.OffsetWith(-1, 0);
		}
		else if(Type == EChessMinigamePieceMoveSubType::Long)
		{
			RookPosition = GetBoardPosition().OffsetWith(-2, 0);
			RookMoveToPosition = KingPosition.OffsetWith(1, 0);
		}

		auto RookTile = Board.GetTileActor(RookPosition);
		auto Rook = RookTile.Piece;
		SetActiveChessPiece(Player, Rook);
		Rook.ShowSkelMeshHideStaticMesh();

		EChessMinigamePieceMovePosition RookMove(Board.GetTileActor(RookMoveToPosition), EChessMinigamePieceMoveType::Castling);
		RookMove.SubType = Type;
		Rook.PlayerInitializedMovement(Player, RookMove);
	}

	bool EvaluateCastling(int MaxTiles)
	{
		const int Dir = FMath::Sign(MaxTiles);
		//const int EndTile = MaxTiles * Dir;
		int X = Dir;
		while(X != MaxTiles + Dir)
		{
			FChessMinigamePosition PositionToTest = GetBoardPosition().OffsetWith(X, 0);
			auto Tile = Board.GetTileActor(PositionToTest);

			if(X != MaxTiles)
			{
				// No free access to the rook
				if(Tile.Piece != nullptr)
					return false;
			}
			else
			{
				auto Rook = Cast<AMinigameChessPieceRook>(Tile.Piece);
				if(Rook == nullptr)
					return false;
				else
					return !Rook.HasMoved();
			}
			
			X += Dir;
		}

		return false;
	}

	// Returns of the king is exposed at the current position 
	bool IsExposedAt(EChessMinigamePieceMovePosition CurrentPiecePosition, TArray<AMinigameChessPieceBase>& OutAttackers)const
	{
		for(auto Position : ExposedPositions)
		{
			if(Position.Tile != CurrentPiecePosition.Tile)
				continue;

			OutAttackers.AddUnique(Position.MoveTypeInstigator);		
		}
		return OutAttackers.Num() > 0;
	}

}