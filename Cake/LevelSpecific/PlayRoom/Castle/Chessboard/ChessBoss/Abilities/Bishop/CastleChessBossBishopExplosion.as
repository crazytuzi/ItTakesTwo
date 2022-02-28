import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
class ACastleChessBossBishopExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraCompNW;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraCompNE;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraCompSW;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraCompSE;

	AChessboard Chessboard;

	float MoveSpeed = 800.f;
	float Lifetime = 4.f;

	float CurrentLifetime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentLifetime += DeltaTime;
		if (CurrentLifetime >= Lifetime || Chessboard.bChessboardDisabled)
			DestroyActor();

		float DeltaMove = MoveSpeed * DeltaTime;
		NiagaraCompNW.SetWorldLocation(NiagaraCompNW.WorldLocation + (NiagaraCompNW.ForwardVector * DeltaMove));
		NiagaraCompNE.SetWorldLocation(NiagaraCompNE.WorldLocation + (NiagaraCompNE.ForwardVector * DeltaMove));
		NiagaraCompSW.SetWorldLocation(NiagaraCompSW.WorldLocation + (NiagaraCompSW.ForwardVector * DeltaMove));
		NiagaraCompSE.SetWorldLocation(NiagaraCompSE.WorldLocation + (NiagaraCompSE.ForwardVector * DeltaMove));
	}
}