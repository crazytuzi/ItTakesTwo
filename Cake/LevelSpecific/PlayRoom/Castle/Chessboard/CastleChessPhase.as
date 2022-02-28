import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

event void FOnPhaseCompleted();

class ACastleChessPhase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UTextRenderComponent PhaseName;
	default PhaseName.bHiddenInGame = true;
	default PhaseName.RelativeLocation = FVector(0, 0, 100.f);
	default PhaseName.WorldSize = 50.f;
	default PhaseName.Text = FText::FromString("Phase Name");
	default PhaseName.HorizontalAlignment = EHorizTextAligment::EHTA_Center;

	AChessboard Chessboard;
	bool bSpawningActive = false;

	UPROPERTY()
	FOnPhaseCompleted OnPhaseCompleted;

	UPROPERTY()
	TArray<FPhaseChessPiece> ChessPiecesInPhase;
	TArray<ACastleEnemy> ActiveChessPieces;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto ChessPieceInPhase : ChessPiecesInPhase)
		{
			UChessPieceComponent ChessPieceComp = UChessPieceComponent::Get(ChessPieceInPhase.ChessPiece);
			if (ChessPieceComp != nullptr)
				ChessPieceComp.OnLanded.AddUFunction(this, n"OnChessPieceLanded");

			ChessPieceInPhase.ChessPiece.OnKilled.AddUFunction(this, n"ChessPieceKilled");
			ActiveChessPieces.Add(ChessPieceInPhase.ChessPiece);
		}
	}

	UFUNCTION()
	void ChessPieceKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		ActiveChessPieces.Remove(Enemy);

		if (ActiveChessPieces.Num() == 0)
			OnPhaseCompleted.Broadcast();
	}

	UFUNCTION()
	void StartPhase(AChessboard Chessboard_)
	{
		Chessboard = Chessboard_;
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Chessboard == nullptr)
			return;

		UpdateSpawnTimer(DeltaTime);
	}

	void UpdateSpawnTimer(float DeltaTime)
	{		
		for (int Index = ChessPiecesInPhase.Num() - 1; Index >= 0; --Index)
		{
			ChessPiecesInPhase[Index].SpawnDelay -= DeltaTime;

			if (ChessPiecesInPhase[Index].SpawnDelay <= 0)
			{
				JumpInChessPieceToGridSquare(Chessboard, ChessPiecesInPhase[Index].ChessPiece, ChessPiecesInPhase[Index].GridSquare, 800.f);

				ChessPiecesInPhase.RemoveAt(Index);
			}
		}
	}

	UFUNCTION()
	void OnChessPieceLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPosition, FVector2D NewGridPosition)
	{
		Enemy.bUnhittable = false;
	}

}

struct FPhaseChessPiece
{
	UPROPERTY()
	ACastleEnemy ChessPiece;

	UPROPERTY()
	FVector2D GridSquare;

	UPROPERTY()
	float SpawnDelay = 0.f;	
}