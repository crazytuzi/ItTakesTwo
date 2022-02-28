import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessPieceLandAttackCapability;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class UCastleEnemyKingLandAttackCapability : UCastleEnemyChessPieceLandAttackCapability
{
	UPROPERTY()
	float DamageRange = 350.f;

	UPROPERTY()
	UNiagaraSystem LandEffect;

	UPROPERTY()
	UForceFeedbackEffect LandFeedback;

	UFUNCTION()
	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousPosition, FVector2D GridPos)
	{
		bDidLanding = true;

		TArray<FVector2D> AffectedGridPositions = PieceComp.Chessboard.GetSurroundingTileLocations(GridPos, true);
		
		for (FVector2D AffectedGridPos : AffectedGridPositions)
		{
			for (auto Player : Chessboard.GetPlayersOnSquare(AffectedGridPos))
			{
				FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;

				const float DamageDealt = FMath::Lerp(MinPlayerDamageDealt, MaxPlayerDamageDealt, (1 - FMath::Clamp(ToPlayer.Size() / DamageRange, 0.f, 1.f)));

				FCastlePlayerDamageEvent Evt;
				Evt.DamageSource = Enemy;
				Evt.DamageDealt = DamageDealt;
				Evt.DamageLocation = Player.ActorCenterLocation;
				Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
				Evt.DamageEffect = DamageEffect;

				BP_OnHitPlayer(Player, Evt);
				Player.DamageCastlePlayer(Evt);

				if (LandFeedback != nullptr)
					Player.PlayForceFeedback(LandFeedback, false, true, n"Land", 1.f);

				if (AffectedGridPos != GridPos)
					continue;

				const float KnockStrengthMax = 500.f;				
				FVector KnockImpulse = ToPlayer.GetSafeNormal() * KnockStrengthMax + FVector(0.f, 0.f, 250.f);
				Player.KnockdownActor(KnockImpulse);
			}
		}
		
		if (LandEffect != nullptr)
		{
			FVector Location = PieceComp.Chessboard.GetSquareCenter(GridPos);
			Niagara::SpawnSystemAtLocation(LandEffect, Location);
		}
	}
}