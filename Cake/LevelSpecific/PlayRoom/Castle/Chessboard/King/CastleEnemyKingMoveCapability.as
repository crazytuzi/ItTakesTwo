import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;
import Rice.Math.MathStatics;

class UCastleEnemyKingMoveCapability : UCastleEnemyChessboardMoveCapability
{    
	default MoveIntervalTurns = 2;

	UFUNCTION(BlueprintOverride)
	FVector2D GetGridMoveLocation()
	{
		float DistanceToPlayer;
		AHazePlayerCharacter NearestPlayer = Math::GetNearestPlayer(Owner.ActorLocation, DistanceToPlayer);

		if (NearestPlayer.IsPlayerDead() && !NearestPlayer.OtherPlayer.IsPlayerDead())
			NearestPlayer = NearestPlayer.OtherPlayer;

		FVector2D TargetGridLocation = PieceComp.Chessboard.GetClosestGridPosition(NearestPlayer.ActorLocation);
		FVector2D ToGrid = TargetGridLocation - PieceComp.GridPosition;
		ToGrid.X = FMath::Clamp(ToGrid.X, -1.f, 1.f);
		ToGrid.Y = FMath::Clamp(ToGrid.Y, -1.f, 1.f);

		return ToGrid;
	}
}