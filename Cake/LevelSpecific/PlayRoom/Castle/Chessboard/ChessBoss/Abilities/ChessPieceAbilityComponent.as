import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.CastleChessBossPieceState;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleDungeonVOBank;

class UChessPieceAbilityComponent : UActorComponent
{
	//const float IdleDuration = 0.f;
	UPROPERTY()
	float TelegraphDuration = 2.2f;
	UPROPERTY()
	float DeathDuration = 0.3f;

	UPROPERTY()
	float TelegraphAlpha = 0.f;

	UPROPERTY()
	ECastleChessBossPieceState State = ECastleChessBossPieceState::Summon;

	AChessboard Chessboard;
	FVector2D Coordinate;
	FVector InitialLocation;
	FVector TargetLocation;
	
	UPROPERTY(Category = Effects)
    UNiagaraSystem SummonLandEffect;

	UPROPERTY(Category = Effects)
    UNiagaraSystem TelegraphStartEffect;

	UPROPERTY(Category = Effects)
    UNiagaraSystem TelegraphEndEffect;

	UPROPERTY(Category = Effects)
    UNiagaraSystem ActionStartEffect;

	UPROPERTY(Category = Effects)
	UNiagaraSystem ActionEndEffect;

	UPROPERTY(Category = Effects)
    UNiagaraSystem ActionTileEffect;

	UPROPERTY(Category = Effects)
    UNiagaraSystem DeathEffect;

	UPROPERTY(Category = Effects)
	TSubclassOf<ADecalActor> TelegraphDecalType;
    TArray<ADecalActor> TelegraphDecals;
	
	UPROPERTY(Category = Summon)
	const float SummonMovementDuration = 1.3f;
	UPROPERTY(Category = Summon)
	const float SummonDuration = 3.f;
	
	UPROPERTY(Category = Summon)
	UCurveFloat VerticalCurve;
	UPROPERTY(Category = Summon)
	UCurveFloat ScaleCurve;
	UPROPERTY(Category = Summon)
	const float SummonHeight = 400.f;

	UPROPERTY(Category = Telegraph)
	UCastleDungeonVOBank VOBank;
	UPROPERTY(Category = Telegraph)
	TPerPlayer<FName> TelegraphBarkName;

	UPROPERTY(Category = Damage)	
	TSubclassOf<UCastleDamageEffect> DamageEffect;

	UPROPERTY(Category = Damage)	
	float Damage = 0.f;

	void Setup(AChessboard _Chessboard, FVector2D _Coordinate, FVector _InitialLocation, FVector _TargetLocation)
	{
		Chessboard = _Chessboard;
		Coordinate = _Coordinate;
		InitialLocation = _InitialLocation;
		TargetLocation = _TargetLocation;
	}
}