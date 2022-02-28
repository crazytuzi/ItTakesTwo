import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;

class UCastleEnemyKnightMoveCapability : UCastleEnemyChessboardMoveCapability
{   
	default bTelegraphBeforeMoving = false;
	default TelegraphDuration = 1.f;

	default PieceGridMovement = FVector2D(1.f, 2.f);
	default MoveIntervalTurns = 6;
	default JumpDurationTurns = 2;

	UFUNCTION(BlueprintOverride)
	FVector2D GetGridMoveLocation()
	{
		int AmountOfTest = 5;

		FVector2D PotentialMovement;
		TArray<FVector2D> ValidPotentialMovements;
		FVector2D PotentialDestination;

		for (int Index = 0, Count = AmountOfTest; Index < Count; ++Index)
		{
			PotentialMovement = ModifyGridMovementForDirection(PieceGridMovement, EChessPieceOrientation(FMath::RandRange(0,3)), bMirror = FMath::RandBool());

			PotentialDestination = PieceComp.GetGridPositionAfterMovement(PotentialMovement, false);


			if (!PieceComp.Chessboard.IsSquareOccupied(PotentialDestination, Owner) && PieceComp.Chessboard.IsGridPositionValid(PotentialDestination))
			{
				ValidPotentialMovements.Add(PotentialMovement);
			}
		}

		if (ValidPotentialMovements.Num() > 0)
		{
			ValidPotentialMovements.Shuffle();

			return ValidPotentialMovements[0];
		}

		return PieceGridMovement;
	}

	void TelegraphStart() override
	{
		Super::TelegraphStart();

		//PieceComp.Chessboard.GetTileActor(DestinationGridPos).TelegraphTile();

		// for (FVector2D GridPos : PieceComp.Chessboard.GetSurroundingTileLocations(DestinationGridPos, true))
		// {
		// 	if (PieceComp.Chessboard.IsGridPositionValid(GridPos))
		// 		PieceComp.Chessboard.GetTileActor(GridPos).TelegraphTile();
		// }
	}
}