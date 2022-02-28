import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessPieceLandAttackCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;

struct FAffectedTilesList
{
	AChessboard Chessboard;
	TArray<FVector2D> AffectedTiles;
};

class UCastleEnemyRookLandAttackCapability : UCastleEnemyChessPieceLandAttackCapability
{
	TArray<FAffectedTilesList> PendingAffects;
	int WaitingAffectsCount = 0;

	UFUNCTION(NetFunction)
	void NetAffectTiles(FAffectedTilesList List)
	{
		if (HasControl())
		{
			CreateTileEffects(List);
		}
		else
		{
			if(WaitingAffectsCount > 0)
			{
				WaitingAffectsCount -= 1;
				CreateTileEffects(List);
			}
			else
			{
				PendingAffects.Add(List);
			}
		}
	}

	void CreateTileEffects(FAffectedTilesList List)
	{
		for (auto GridPosition : List.AffectedTiles)
			List.Chessboard.GetTileActor(GridPosition).DropTile();
	}

	void OnMoveStarted(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPos, FVector2D GridPos) override
	{
		FVector2D MoveDirection = (GridPos - PreviousGridPos).SignVector;

		TArray<FVector2D> AffectedGridPositions;
		AffectedGridPositions = GetTilesInLine(PreviousGridPos, GridPos);

		for (FVector2D GridPosition : AffectedGridPositions)
		{
			Chessboard.ActorOccupiesSquare(GridPosition, Enemy);
		}
	}

	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPos, FVector2D GridPos) override
	{
		bDidLanding = true;

		// FVector2D MoveDirection = (GridPos - PreviousGridPos).SignVector;

		// TArray<FVector2D> AffectedGridPositions;
		// AffectedGridPositions = GetTilesInLine(PreviousGridPos, GridPos);

		// for (FVector2D GridPosition : AffectedGridPositions)
		// {
		// 	Chessboard.RemoveActorFromSquare(GridPosition, Enemy);
		// }

		// if (HasControl())
		// {
		// 	FAffectedTilesList AffectedTiles;
		// 	AffectedTiles.Chessboard = Chessboard;

		// 	for (FVector2D GridPosition : AffectedGridPositions)
		// 	{
		// 		if (!Chessboard.IsSquareOccupied(GridPosition))
		// 			AffectedTiles.AffectedTiles.Add(GridPosition);
		// 	}

		// 	NetAffectTiles(AffectedTiles);
		// }
		// else
		// {
		// 	if (PendingAffects.Num() > 0)
		// 	{
		// 		CreateTileEffects(PendingAffects[0]);
		// 		PendingAffects.RemoveAt(0);
		// 	}
		// 	else
		// 	{
		// 		WaitingAffectsCount += 1;
		// 	}
		// }
		
		/*
		Used for getting the forward and backwards limit of the movement - feels a bit weird though
		Seems to return 0,0 on some moves. Works 80% of the time though
		FVector2D ForwardsTileLimit;
		FVector2D BackwardsTileLimit;

		// Find forwards limit
		for (int Index = 7; Index > 0; --Index)
		{
			if (PieceComp.Chessboard.IsGridPositionValid(GridPos + (MoveDirection * Index)))
			{
				ForwardsTileLimit = GridPos + (MoveDirection * Index);
				break;
			}
		}

		// Find backwards limit
		for (int Index = 7; Index > 0; --Index)
		{
			if (PieceComp.Chessboard.IsGridPositionValid(GridPos + (MoveDirection * Index * -1)))
			{
				BackwardsTileLimit = GridPos + (MoveDirection * Index * -1);
				break;
			}
		}
			SpawnActor(TileEffect, Chessboard.GetSquareCenter(PreviousGridPos), FRotator::ZeroRotator);
			SpawnActor(TileEffect, Chessboard.GetSquareCenter(GridPos), FRotator::ZeroRotator);
		*/
	}

	TArray<FVector2D> GetTilesInLine(FVector2D StartGridPos, FVector2D EndGridPos)
	{
		TArray<FVector2D> TilesInLine;

		FVector2D Movement = EndGridPos - StartGridPos;
		FVector2D MoveDirection = GetSignVector2D(Movement);		
		int MovementLength = FMath::Max(FMath::Abs(Movement.X), FMath::Abs(Movement.Y));
		

		for (int Index = 0, Count = MovementLength; Index <= Count; ++Index)
		{
			FVector2D TileLocation = StartGridPos + (MoveDirection * Index);

			if (TileLocation != EndGridPos)
				TilesInLine.Add(StartGridPos + (MoveDirection * Index));
		}

		return TilesInLine;
	}

	FVector2D GetSignVector2D(FVector2D Vector)
	{
		FVector2D SignedVector = Vector;
		SignedVector.X = FMath::Sign(SignedVector.X);
		SignedVector.Y = FMath::Sign(SignedVector.Y);

		return SignedVector;
	}
}