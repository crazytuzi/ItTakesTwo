import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessPieceLandAttackCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;

UCLASS(Abstract)
class UCastleEnemyKnightLandAttackCapability : UCastleEnemyChessPieceLandAttackCapability
{
	UPROPERTY()
	UNiagaraSystem LandingEffect;

	default MinPlayerDamageDealt = 60.f;
	default MaxPlayerDamageDealt = 80.f;

	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPos, FVector2D GridPos)
	{
		bDidLanding = true;
        float Damage = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);

		TArray<FVector2D> AffectedGridPositions;
		AffectedGridPositions = GetTilesAroundTile(GridPos);

		for (FVector2D GridPosition : AffectedGridPositions)
		{
			if (PieceComp.Chessboard.IsGridPositionValid(GridPosition))
			{
				// Damage players on tile
				for (auto Player : Chessboard.GetPlayersOnSquare(GridPosition))
				{
					FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;

					FCastlePlayerDamageEvent Evt;
					Evt.DamageSource = Enemy;
					Evt.DamageDealt = Damage;
					Evt.DamageLocation = Player.ActorCenterLocation;
					Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
					Evt.DamageEffect = DamageEffect;

					BP_OnHitPlayer(Player, Evt);
					Player.DamageCastlePlayer(Evt);
				}
				
				// Spawn effect
				Niagara::SpawnSystemAtLocation(LandingEffect, Chessboard.GetSquareCenter(GridPosition), FRotator::ZeroRotator);	
			}
		}
		
	}

	TArray<FVector2D> GetTilesAroundTile(FVector2D EndGridPos)
	{
		TArray<FVector2D> TilesAroundTile;
		TilesAroundTile.Add(EndGridPos);
		TilesAroundTile.Add(EndGridPos + FVector2D(1, 0));
		TilesAroundTile.Add(EndGridPos + FVector2D(1, 1));
		TilesAroundTile.Add(EndGridPos + FVector2D(0, 1));
		TilesAroundTile.Add(EndGridPos + FVector2D(-1, 1));
		TilesAroundTile.Add(EndGridPos + FVector2D(-1, 0));
		TilesAroundTile.Add(EndGridPos + FVector2D(-1, -1));
		TilesAroundTile.Add(EndGridPos + FVector2D(0, -1));
		TilesAroundTile.Add(EndGridPos + FVector2D(1, -1));
	
		return TilesAroundTile;
	}
}