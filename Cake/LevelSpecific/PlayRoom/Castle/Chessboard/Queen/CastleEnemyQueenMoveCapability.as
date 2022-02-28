import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleEnemyChessboardMoveCapability;

class UCastleEnemyQueenMoveCapability : UCastleEnemyChessboardMoveCapability
{    
	int MoveDistance = 7.f;
	bool bMoveDiagonally = false;

	UPROPERTY()
	UNiagaraSystem MoveSystem;
	UNiagaraComponent MoveSystemComp;

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{		
		if (MoveSystemComp != nullptr)
		{
			MoveSystemComp.Deactivate();
			MoveSystemComp == nullptr;
		}
	}

	void ExecuteMove(FExecuteMoveData MoveData) override
	{
		Super::ExecuteMove(MoveData);

		if (MoveSystem != nullptr)
			MoveSystemComp = Niagara::SpawnSystemAttached(MoveSystem, Owner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
	}
	
	void FinishMove() override
	{
		Super::FinishMove();

		if (MoveSystemComp != nullptr)
		{
			MoveSystemComp.Deactivate();
			MoveSystemComp == nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	FVector2D GetGridMoveLocation()
	{
		// Get a random direction;
		FVector2D MoveDirection = GetMoveDirection(bMoveDiagonally);
		bMoveDiagonally = !bMoveDiagonally;

		int MoveDistanceMax = 0;

		for (int Index = MoveDistance; Index > 1; --Index)
		{
			FVector2D GridPositionAfterMovement;
			GridPositionAfterMovement = PieceComp.GetGridPositionAfterMovement(MoveDirection * Index, false);

			if (!PieceComp.Chessboard.IsSquareOccupied(GridPositionAfterMovement, Owner) && PieceComp.Chessboard.IsGridPositionValid(GridPositionAfterMovement))
			{
				MoveDistanceMax = Index;
				break;
			}
		}

		int MoveDistanceMin;
		if (MoveDistanceMax != 0)
			MoveDistanceMin = 1;

		int CurrentMoveDistance;
		CurrentMoveDistance = FMath::RandRange(MoveDistanceMin, MoveDistanceMax);

		return MoveDirection * CurrentMoveDistance;		
	}

	FVector2D GetMoveDirection(bool bShouldMoveDiagonally)
	{
		FVector2D Direction;		

		if (bShouldMoveDiagonally)
		{
			Direction.X = FMath::RandBool() ? 1 : -1;
			Direction.Y = FMath::RandBool() ? 1 : -1;
		}
		else
		{
			int DirectionInt = FMath::RandRange(0, 3);

			FVector2D MoveDirectionForward;
			MoveDirectionForward.X = 1;

			FVector2D MoveDirectionRight;
			MoveDirectionRight.Y = 1;

			FVector2D MoveDirectionBackwards;
			MoveDirectionBackwards.X = -1;

			FVector2D MoveDirectionLeft;
			MoveDirectionLeft.Y = -1;

			if (DirectionInt == 0)
				Direction = MoveDirectionForward;
			else if (DirectionInt == 1)
				Direction = MoveDirectionRight;
			else if (DirectionInt == 2)
				Direction = MoveDirectionBackwards;
			else if (DirectionInt == 3)
				Direction = MoveDirectionLeft;
		}

		return Direction;
	}
}
