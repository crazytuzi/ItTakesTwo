import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTelegraph;
import Rice.Math.MathStatics;

class UCastleEnemyPawnMoveCapability : UCastleEnemyChessboardMoveCapability
{    
	default PieceGridMovement = FVector2D(0.f, 1.f);
	default MoveIntervalTurns = 4;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);

		Enemy.CapsuleComponent.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	FVector2D GetGridMoveLocation()
	{
		float DistanceToPlayer;
		AHazePlayerCharacter NearestPlayer = Math::GetNearestPlayer(Owner.ActorLocation, DistanceToPlayer);

		FVector2D TargetGridLocation = PieceComp.Chessboard.GetClosestGridPosition(NearestPlayer.ActorLocation);
		FVector2D ToGrid = TargetGridLocation - PieceComp.GridPosition;
		ToGrid.X = FMath::Clamp(ToGrid.X, -1.f, 1.f);
		ToGrid.Y = FMath::Clamp(ToGrid.Y, -1.f, 1.f);

		return ToGrid;



		// FVector2D GridMovement = PieceGridMovement * (bIsReversed ? -1 : 1);

		// FVector2D CurrentGridPosition = PieceComp.GridPosition;
		// FVector2D FutureGridPosition = PieceComp.GetGridPositionAfterMovement(PieceGridMovement, bIsReversed);

		// return GridMovement;
	}

	void ExecuteMove(FExecuteMoveData MoveData)
	{
		Super::ExecuteMove(MoveData);

		Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

		OverlappingPlayers.Empty();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Enemy.CapsuleComponent.IsOverlappingActor(Player))
				OverlappingPlayers.Add(Player);
		}
	}

	void FinishMove()
	{
		if (OverlappingPlayers.Num() == 0)
			Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

		Super::FinishMove();
	}

	UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player != nullptr)
			OverlappingPlayers.Remove(Player);

		if (OverlappingPlayers.Num() == 0)
			Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
    }

	void TelegraphStart() override
	{
		// Super::TelegraphStart();
	
		// TArray<FVector2D> TelegraphedGridPositions;				
		// TelegraphedGridPositions.Add(DestinationGridPos);

		// TelegraphedGridPositions.Add(DestinationGridPos - (PieceGridMovement * (bIsReversed ? -1 : 1)));

		// // FVector2D RightDamage = DestinationGridPos + PieceComp.ModifyGridMovementForOrientation(PieceGridMovement * (bIsReversed ? -1 : 1));
		// // RightDamage.X += 1;
		// // TelegraphedGridPositions.Add(RightDamage);

		// // FVector2D LeftDamage = DestinationGridPos + PieceComp.ModifyGridMovementForOrientation(PieceGridMovement * (bIsReversed ? -1 : 1));
		// // LeftDamage.X += -1;
		// // TelegraphedGridPositions.Add(LeftDamage);

		// for (FVector2D TelegraphedGridPosition : TelegraphedGridPositions)
		// {
		// 	if (!PieceComp.Chessboard.IsGridPositionValid(TelegraphedGridPosition))
		// 		continue;			

		// 	PieceComp.Chessboard.GetTileActor(TelegraphedGridPosition).TelegraphTile();
		// }
	}
}