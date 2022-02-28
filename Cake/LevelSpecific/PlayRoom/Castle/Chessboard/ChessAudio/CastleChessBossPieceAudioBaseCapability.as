import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleEnemyAudioBaseCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

class UCastleChessBossPieceAudioBaseCapability : UCastleEnemyAudioBaseCapability
{
	UChessPieceComponent ChessPieceComp;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent PreMovementEvent;

	UPROPERTY(Category = "Movement")
	UAkAudioEvent OnReachedTargetTileEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		bBlockMovementAudio = true;

		ChessPieceComp = UChessPieceComponent::Get(CastleEnemy);

		ChessPieceComp.OnMoveStarted.AddUFunction(this, n"OnStartMove");
		ChessPieceComp.OnLanded.AddUFunction(this, n"OnStopMove");
	}

	UFUNCTION()
	void OnStartMove(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D DestinationGridPosition)
	{
		bBlockMovementAudio = false;
		EnemyHazeAkComp.HazePostEvent(PreMovementEvent);
	}

	UFUNCTION()
	void OnStopMove(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D NewGridPosition)
	{
		EnemyHazeAkComp.HazePostEvent(OnReachedTargetTileEvent);
	}
}