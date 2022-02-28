import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;

class UCastleEnemyRookMoveCapability : UCastleEnemyChessboardMoveCapability
{    
	UFUNCTION(BlueprintOverride)
	FVector2D GetGridMoveLocation()
	{
		// Get a random direction;
		FVector2D MoveDirection;
		int DirectionInt = FMath::RandRange(0, 3);

		FVector2D MoveDirectionForward;
		MoveDirectionForward.X = 1;

		FVector2D MoveDirectionRight;
		MoveDirectionRight.Y = 1;

		FVector2D MoveDirectionBackwards;
		MoveDirectionBackwards.X = -1;

		FVector2D MoveDirectionLeft;
		MoveDirectionLeft.Y = -1;

		if (DirectionInt == 0)
			MoveDirection = MoveDirectionForward;
		else if (DirectionInt == 1)
			MoveDirection = MoveDirectionRight;
		else if (DirectionInt == 2)
			MoveDirection = MoveDirectionBackwards;
		else if (DirectionInt == 3)
			MoveDirection = MoveDirectionLeft;

		int MoveDistanceMax = 0;

		for (int Index = 7, Count = 7; Index > 1; --Index)
		{
			FVector2D GridPositionAfterMovement; 
			GridPositionAfterMovement = PieceComp.GetGridPositionAfterMovement(MoveDirection * Index, false);

			if (PieceComp.Chessboard.IsGridPositionValid(GridPositionAfterMovement) && !PieceComp.Chessboard.IsSquareOccupied(GridPositionAfterMovement, Owner))
			{
				MoveDistanceMax = Index;
				break;
			}
		}

		int MoveDistanceMin;
		if (MoveDistanceMax != 0)
			MoveDistanceMin = MoveDistanceMax / 3;

		int MoveDistance;


		MoveDistance = FMath::RandRange(MoveDistanceMin, MoveDistanceMax);	


		return MoveDirection * MoveDistance;
	}

	void TelegraphStart() override
	{
		// FVector2D DeltaMove = DestinationGridPos - PieceComp.GridPosition;
		// int Distance = FMath::Abs(DeltaMove.X + DeltaMove.Y);
		// FVector2D Direction = (DestinationGridPos - PieceComp.GridPosition).GetSafeNormal();

		// for (FVector2D GridPos : PieceComp.Chessboard.GetTilesInLine(PieceComp.GridPosition, DestinationGridPos, true))
		// {
		// 	if (PieceComp.Chessboard.IsGridPositionValid(GridPos))
		// 		PieceComp.Chessboard.GetTileActor(GridPos).TelegraphTile();
		// }
	}

	int MirrorChance()
	{
		bool bShouldMirror = FMath::RandBool();
		return bShouldMirror ? 1 : -1;
	}
};