import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class UCastleEnemyBishopMoveCapability : UCastleEnemyChessboardMoveCapability
{
	FVector DestinationLocation;
	const float Speed = 1600.f;

	const int MoveDistanceMin = 3;
	const int MoveDistanceMax = 5;
	
	TArray<FVector2D> MoveDirections;
	default MoveDirections.Add(FVector2D(1.f, 1.f));
	default MoveDirections.Add(FVector2D(1.f, -1.f));
	default MoveDirections.Add(FVector2D(-1.f, 1.f));
	default MoveDirections.Add(FVector2D(-1.f, -1.f));

	bool bCollisionSetToOverlap = false;
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
		// Try and do a 3/4/5 move. If you can't, go back where you came from
		int MoveDistance = FMath::RandRange(MoveDistanceMin, MoveDistanceMax);
		FVector2D MoveDirection;
	
		MoveDirections.Shuffle();
		for (int Index = 0; Index < MoveDirections.Num(); Index++)
		{
			FVector2D Move = MoveDirections[Index] * MoveDistance;
			FVector2D GridPositionAfterMovement = PieceComp.GetGridPositionAfterMovement(Move, false);

			if (PieceComp.Chessboard.IsSquareOccupied(GridPositionAfterMovement, Owner))
				continue;

			if (!PieceComp.Chessboard.IsGridPositionValid(GridPositionAfterMovement))
				continue;

			MoveDirection = MoveDirections[Index];
			break;
		}

		return MoveDirection * MoveDistance;
	}

	void ExecuteMove(FExecuteMoveData MoveData)
	{
		Super::ExecuteMove(MoveData);

		DestinationLocation = OriginalPosition + XMovement + YMovement;
		// Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

		// OverlappingPlayers.Empty();
		// for (AHazePlayerCharacter Player : Game::Players)
		// {
		// 	if (Enemy.CapsuleComponent.IsOverlappingActor(Player))
		// 		StartedOverlappingPlayer(Player);
		// }
	}

	void FinishMove()
	{
		if (OverlappingPlayers.Num() == 0)
			Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

		Super::FinishMove();
	}

	void StartedOverlappingPlayer(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Add(Player);

		FVector MoveDirection = (DestinationLocation - OriginalPosition).GetSafeNormal();
		FVector ToPlayer = (Player.ActorLocation - Owner.ActorLocation).ConstrainToPlane(FVector::UpVector);

		FVector KnockbackDirection = (MoveDirection + ToPlayer) / 2.f;

		// Knock back players if we hit them				
		if (!Player.HasControl())
			return;
		if (Player.IsAnyCapabilityActive(n"KnockDown"))
			return;

		float KnockForce = 600.f;
		FVector KnockImpulse = KnockbackDirection * KnockForce + FVector(0.f, 0.f, 200.f);
		Player.KnockdownActor(KnockImpulse);
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

	void TelegraphUpdate(float Percentage)
	{
		//Enemy.Mesh.SetRelativeRotation(FRotator(45.f * Percentage, 0.f, 0.f));
	}

	void UpdateMove(float DeltaTime)
	{	
		FVector TargetLocation = OriginalPosition + XMovement + YMovement;

		FVector MoveDirection = OriginalPosition - TargetLocation;
		float Distance = MoveDirection.Size();
		MoveDuration = Distance / Speed;

		Super::UpdateMove(DeltaTime);

		//if ()
    }
};