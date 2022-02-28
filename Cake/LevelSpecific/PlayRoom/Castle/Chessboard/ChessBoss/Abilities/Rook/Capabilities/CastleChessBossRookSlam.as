import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;

class ACastleChessBossRookSlam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AChessboard Chessboard;
	ACastleEnemy Rook;
	TArray<FTileSquareTimer> TilesToLower;
	float Duration;

	void Setup(AChessboard _Chessboard, ACastleEnemy _Rook, TArray<FTileSquareTimer> _TilesToLower, float _Duration)
	{
		Chessboard = _Chessboard;
		Rook = _Rook;
		TilesToLower = _TilesToLower;
		Duration = _Duration;
		Chessboard.bTilesStartedDropping = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TilesToLower.Num() > 0)
			UpdateAndLowerTiles(DeltaTime);
			
		if (TilesToLower.Num() == 0 || Chessboard.bChessboardDisabled)
			DestroyActor();
	}

	void UpdateAndLowerTiles(float DeltaTime)
	{
		for (int Index = TilesToLower.Num() - 1; Index >= 0; Index--)
		{
			TilesToLower[Index].Duration -= DeltaTime;

			if (TilesToLower[Index].Duration <= 0.f)
			{
				Chessboard.GetTileActor(TilesToLower[Index].TileCoordinate).DropTile(Duration);
				Chessboard.RemoveActorFromSquare(TilesToLower[Index].TileCoordinate, Rook);				
				TilesToLower.RemoveAt(Index);
			}
		}			
	}
}