import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleDungeonVOBank;
class ACastleChessBossBishopExplosionFire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UNiagaraComponent NiagaraComp;
	UPROPERTY()
	UNiagaraSystem NiagaraEffect;

	UChessPieceAbilityComponent PieceAbilityComp;

	UPROPERTY()
	UCastleDungeonVOBank VOBank;

	AChessboard Chessboard;
	FVector2D Coordinate;

	bool bEnabled = false;
	float IdleTime = 0.f;
	float ActiveDuration = 4.f;

	float CurrentDuration = 0.f;

	const float DamageTickInterval = 0.2f;
	float DamageTickTimer = 0.f;

	void Setup(AChessboard _Chessboard, UChessPieceAbilityComponent _PieceAbilityComp, FVector2D _Coordinate, float _IdleTime = 0.f, float _ActiveDuration = 4.f)
	{
		Chessboard = _Chessboard;
		PieceAbilityComp = _PieceAbilityComp;
		Coordinate = _Coordinate;
		IdleTime = _IdleTime;
		ActiveDuration = _ActiveDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentDuration += DeltaTime;

		if (!bEnabled && CurrentDuration >= IdleTime)
		{
			bEnabled = true;

			if (NiagaraEffect != nullptr)
				NiagaraComp = Niagara::SpawnSystemAtLocation(NiagaraEffect, ActorLocation);
		}

		if (!bEnabled)
			return;

		DamageTickTimer += DeltaTime;
		if (DamageTickTimer >= DamageTickInterval)
		{
			// Damage players
			DamagePlayersOnTile();
			DamageTickTimer = 0.f;
		}

		if (CurrentDuration >= IdleTime + ActiveDuration || Chessboard.bChessboardDisabled)
		{
			if (NiagaraComp != nullptr)
				NiagaraComp.Deactivate();
			DestroyActor();
		}
	}

	void DamagePlayersOnTile()
	{
		for (AHazePlayerCharacter Player : Chessboard.GetPlayersOnSquare(Coordinate))
		{
			FVector ToPlayer = Player.ActorCenterLocation - ActorLocation;

			FCastlePlayerDamageEvent Damage;
            Damage.DamageSource = Cast<AHazeActor>(PieceAbilityComp.Owner);
            Damage.DamageDealt = PieceAbilityComp.Damage;
            Damage.DamageEffect = PieceAbilityComp.DamageEffect;
            Damage.DamageLocation = Player.ActorCenterLocation;
            Damage.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);

            Player.DamageCastlePlayer(Damage);

			if (Player.IsMay())
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleChessboardFireDamageMay");
			else
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleChessboardFireDamageCody");
		}
	}
}