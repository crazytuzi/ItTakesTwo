import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessPieceLandAttackCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;

UCLASS(Abstract)
class UCastleEnemyBishopLandAttackCapability : UCastleEnemyChessPieceLandAttackCapability
{
	int SpawnEffectCounter = 0;

	UPROPERTY()
	TSubclassOf<ACastleChessTileEffect> TileEffect;

	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPos, FVector2D GridPos)
	{
		bDidLanding = true;
        float Damage = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);

		FVector2D MoveDirection = (GridPos - PreviousGridPos).SignVector;


		// TArray<FVector2D> AffectedGridPositions;
		// AffectedGridPositions = GetTilesInLine(PreviousGridPos, GridPos);

		// for (FVector2D GridPosition : AffectedGridPositions)
		// {
		// 	auto Effect = SpawnActor(TileEffect, Chessboard.GetSquareCenter(GridPosition), FRotator::ZeroRotator, bDeferredSpawn = true);			
		// 	Effect.MakeNetworked(this, SpawnEffectCounter++);
		// 	FinishSpawningActor(Effect);
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
		FVector2D MoveDirection = Movement.SignVector;		
		int MovementLength = FMath::Abs(Movement.X);

		for (int Index = 0, Count = MovementLength; Index <= Count; ++Index)
		{
			TilesInLine.Add(StartGridPos + (MoveDirection * Index));
		}

		return TilesInLine;
	}
}