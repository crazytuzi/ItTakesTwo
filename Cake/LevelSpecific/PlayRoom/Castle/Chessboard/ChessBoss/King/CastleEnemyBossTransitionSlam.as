import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;

class ACastleEnemyBossTransitionSlam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent PlayerBlocker;
	default PlayerBlocker.SetCollisionProfileName(n"BlockAllDynamic");
	default PlayerBlocker.SetHiddenInGame(false);

	AChessboard Chessboard;

	const float SlamWaveSpeed = 800.f;

	// How many tiles it will affect in width
	const int TileWidth = 3;
	// Will check the percentage distance away using depth range
	const int TileDepth = 3;

	void StartSlam(AChessboard InChessboard)
	{
		Chessboard = InChessboard;

		FVector PlayerBlockerExtents;
		PlayerBlockerExtents.X = Chessboard.SquareSize.Y / 2.f;
		PlayerBlockerExtents.Y = Chessboard.SquareSize.X * TileWidth / 2.f;
		PlayerBlockerExtents.Z = 150.f;
		PlayerBlocker.SetRelativeLocation(FVector(0.f, 0.f, PlayerBlockerExtents.Z));
		PlayerBlocker.SetBoxExtent(PlayerBlockerExtents);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MoveSlamWave(DeltaTime);
		UpdateNearbyTiles(DeltaTime);
	}

	void MoveSlamWave(float DeltaTime)
	{
		AddActorWorldOffset(ActorForwardVector * SlamWaveSpeed * DeltaTime);
	}

	void UpdateNearbyTiles(float DeltaTime)
	{
		FVector OriginTestLocation = ActorLocation;
		OriginTestLocation.Z = Chessboard.ActorLocation.Z;

		float WaveForwardDistance = Chessboard.SquareSize.Y * (TileDepth - 1);
		float WaveRightDistance = Chessboard.SquareSize.X * (TileWidth - 1);

		float WaveForwardStepDistance = Chessboard.SquareSize.Y;
		float WaveRightStepDistance = Chessboard.SquareSize.X;

		for (int WidthIndex = 0; WidthIndex < TileWidth; WidthIndex++)
		{
			FVector WidthOriginLocation = OriginTestLocation + ActorRightVector * ((-WaveRightDistance / 2.f) + (WaveRightStepDistance * WidthIndex));

			for (int Index = 0; Index < TileDepth; Index++)
			{
				FVector TestLocation = WidthOriginLocation + (-ActorForwardVector * WaveForwardStepDistance * Index);
				//DebugDrawArrow(TestLocation, TestLocation + FVector(0.f, 0.f, 500.f));

				FVector2D TestTileCoordinate;
				Chessboard.GetGridPosition(TestLocation, TestTileCoordinate);
				AChessTile TestedChessTile = Chessboard.GetTileActor(TestTileCoordinate);

				if (TestedChessTile == nullptr)
					continue;

				float Distance = (WidthOriginLocation - TestedChessTile.ActorLocation).Size();
				float DistanceCheck = WaveForwardStepDistance + (WaveForwardStepDistance);
				float Alpha = (DistanceCheck - Distance) / DistanceCheck;

				//TestedChessTile.TileMeshRoot.SetRelativeLocation(FVector(0.f, 0.f, Alpha * 500.f));
			}
		}

		FVector2D ClosestGridCoordinate = Chessboard.GetClosestGridPosition(ActorLocation);
		FVector GridLocation = Chessboard.GetSquareCenter(ClosestGridCoordinate);

		if ((GridLocation - ActorLocation).Size() > Chessboard.SquareSize.Y * 3)
			DestroyActor();
	}
}