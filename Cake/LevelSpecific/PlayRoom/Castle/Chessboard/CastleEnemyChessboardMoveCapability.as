import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Rice.Math.MathStatics;

struct FExecuteMoveData
{
	FVector2D DestinationGridPos;
	bool bReversed;
	float MoveDuration;
	FVector Offset;
	float JumpHeight;
	FQuat DestRotation;
};

class UCastleEnemyChessboardMoveCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::ActionMovement;
    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"ChessboardMovement");

	// Amount of spaces in X and Y on the board that the piece will move
	UPROPERTY()
	FVector2D PieceGridMovement;

	// Interval in chess "turns" between the piece moving
	UPROPERTY()
	int MoveIntervalTurns = 5;

	// Jump height of this piece's move
	UPROPERTY()
	float JumpHeight = 200.f;

	// Duration of the telegraph the piece does before actually moving
	UPROPERTY()
	float TelegraphDuration = 2.f;

	/*
		If true it will telegraph, then move 
		If false it will finish telegraph and move at the end of the move
	*/
	UPROPERTY()
	bool bTelegraphBeforeMoving = false;

	// Duration in chessboard turns that the piece spends in the air while jumping
	UPROPERTY()
	float JumpDurationTurns = 1.f;

	// Curve used for lateral movement in board X in the jump
	UPROPERTY()
	UCurveFloat LateralXMoveCurve;

	// Curve used for lateral movement in board Y in the jump
	UPROPERTY()
	UCurveFloat LateralYMoveCurve;

	// Curve used for vertical movement in the jump
	UPROPERTY()
	UCurveFloat VerticalMoveCurve;

	// Curve used for telegraphing
	UPROPERTY()
	UCurveFloat TelegraphCurve;

	// Curve used to rotate in the direction we will be moving, applied during telegraph
	UPROPERTY()
	UCurveFloat TelegraphRotationCurve;

	// Random offset from the center of the square to land
	UPROPERTY()
	float PositionRandomness = 25.f;

	// Random offset in time for the duration of their move, in percentage of turn length
	UPROPERTY()
	float TimeRandomness = 0.1f;

	// Random offset to the height the piece jumps, in percentage of jump height
	UPROPERTY()
	float HeightRandomness = 0.1f;

	// if the chess piece is knocked back, the movement will be delayed until the next turn
	UPROPERTY()
	bool bKnockbacksInterruptMovement = false;

    ACastleEnemy Enemy;
    UHazeBaseMovementComponent MoveComp;
	UPROPERTY()
	UChessPieceComponent PieceComp;

	int NextMoveTurn = -1;

	bool bIsMoving = false;
	UPROPERTY()
	bool bIsReversed = false;
	bool bTelegraphStarted = false;
	bool bTelegraphDone = false;
	float MoveDuration = 0.f;
	float MoveTimer = 0.f;
	FVector OriginalPosition;
	FVector MoveDestination;
	FVector XMovement;
	FVector YMovement;
	FQuat OriginalRotation;
	FQuat DestinationRotation;
	FVector2D DestinationGridPos;
	float CurrentJumpHeight = 0.f;
	int StuckTurns = 0;
	TArray<FExecuteMoveData> PendingMoves;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);

        Enemy.OnKnockedBack.AddUFunction(this, n"OnKnockedBack");

		Enemy.BlockCapabilities(n"CastleEnemyMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void OnRemoved()
    {
		Enemy.UnblockCapabilities(n"CastleEnemyMovement", this);
	}

    UFUNCTION()
    void OnKnockedBack(ACastleEnemy KnockedEnemy, FCastleEnemyKnockbackEvent Event)
    {
		if (PieceComp.Chessboard == nullptr)
			return;

		if (!bKnockbacksInterruptMovement)
			return;

		if (PieceComp.Chessboard.CurrentTurn >= NextMoveTurn - 1)
			NextMoveTurn += 1;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (PieceComp.Chessboard == nullptr)
			return EHazeNetworkActivation::DontActivate; 
		if (PieceComp.State != EChessPieceState::Fighting)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (PieceComp.Chessboard == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
		if (PieceComp.State != EChessPieceState::Fighting)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (NextMoveTurn == -1)
			NextMoveTurn = PieceComp.Chessboard.CurrentTurn + PieceComp.StartDelayTurns;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		if (bIsMoving)
		{
			if (!bTelegraphDone)
				TelegraphDone();
			FinishMove();
			bIsMoving = false;
		}
    }

	void StartMove()
	{
		if (HasControl())
		{
			FVector2D CurrentGridPos = PieceComp.GridPosition;

			DestinationGridPos = CurrentGridPos;
			DestinationGridPos += PieceComp.ModifyGridMovementForOrientation(GetGridMoveLocation());

			if (PieceComp.Chessboard.IsSquareOccupied(DestinationGridPos, Owner))
			{
				NextMoveTurn += 1;
				StuckTurns += 1;
				if (StuckTurns > MoveIntervalTurns)
				{
					bIsReversed = !bIsReversed;
					StuckTurns = 0;
				}
				return;
			}

			if (!PieceComp.Chessboard.IsGridPositionValid(DestinationGridPos))
			{
				bIsReversed = !bIsReversed;
				return;
			}

			FExecuteMoveData MoveData;
			MoveData.DestinationGridPos = DestinationGridPos;
			MoveData.bReversed = bIsReversed;
			MoveData.MoveDuration = PieceComp.Chessboard.GetTurnDuration() * FMath::RandRange(1.f-TimeRandomness, 1.f+TimeRandomness) * JumpDurationTurns;

			NextMoveTurn = PieceComp.Chessboard.CurrentTurn + MoveIntervalTurns;

			MoveData.Offset = FMath::VRand() * FMath::RandRange(0.f, PositionRandomness);
			MoveData.Offset.Z = 0.f;

			MoveData.JumpHeight = JumpHeight * FMath::RandRange(1.f - HeightRandomness, 1.f + HeightRandomness);
			MoveData.DestRotation = Math::MakeQuatFromX(MoveDestination - OriginalPosition);

			NetStartMove(MoveData);
		}
		else if(PendingMoves.Num() != 0)
		{
			ExecuteMove(PendingMoves[0]);
			PendingMoves.RemoveAt(0);
		}
	}

	UFUNCTION(NetFunction)
	void NetStartMove(FExecuteMoveData MoveData)
	{
		if (HasControl())
			ExecuteMove(MoveData);
		else
			PendingMoves.Add(MoveData);
	}

	void ExecuteMove(FExecuteMoveData MoveData)
	{
		FVector2D CurrentGridPos = PieceComp.GridPosition;

		DestinationGridPos = MoveData.DestinationGridPos;
		bIsReversed = MoveData.bReversed;

		bIsMoving = true;
		bTelegraphDone = false;
		MoveDuration = MoveData.MoveDuration;
		MoveTimer = 0.f;
		StuckTurns = 0;

		OriginalPosition = Enemy.ActorLocation;
		OriginalRotation = Enemy.ActorQuat;

		MoveDestination = PieceComp.Chessboard.GetSquareCenter(DestinationGridPos);
		MoveDestination += MoveData.Offset;

		CurrentJumpHeight = MoveData.JumpHeight;

		XMovement = (MoveDestination - Enemy.ActorLocation).ProjectOnTo(PieceComp.Chessboard.GetXVector());
		YMovement = (MoveDestination - Enemy.ActorLocation) - XMovement;

		DestinationRotation = MoveData.DestRotation;
		PieceComp.Chessboard.ActorOccupiesSquare(DestinationGridPos, Owner);

		Owner.SetCapabilityActionState(n"NeutralizeKnockback", EHazeActionState::Active);

		PieceComp.StartMoving(CurrentGridPos + PieceGridMovement);


	}

	UFUNCTION(BlueprintEvent)
	FVector2D GetGridMoveLocation()
	{
		return PieceGridMovement * (bIsReversed ? -1.f : 1.f);
	}

	void FinishMove()
	{
		Owner.SetCapabilityActionState(n"NeutralizeKnockback", EHazeActionState::Inactive);

		bIsMoving = false;
		PieceComp.LandOnPosition(DestinationGridPos);
	}

	void TelegraphStart()
	{		
	}

	void TelegraphUpdate(float Percentage)
	{

	}

	void TelegraphDone()
	{
		PieceComp.TelegraphDone(DestinationGridPos);
		bTelegraphDone = true;
		bTelegraphStarted = false;
	}

	bool CanMove()
	{
		// Only the King and Queen have this capability now. 

		if (Enemy.Health <= 150.f)
			return false;

		if (Game::May.IsPlayerDead() && Game::Cody.IsPlayerDead())
			return false;

		// Dont move if you are spawning (spawns on deactivate)
		if (PieceComp.Chessboard.bSpawningWaves)
			return false;

		return true;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (bIsMoving)
		{
			UpdateMove(DeltaTime);
		}
		else if (PieceComp.Chessboard.CurrentTurn >= NextMoveTurn && CanMove())
		{
			StartMove();
		}
	}

	void UpdateMove(float DeltaTime)
	{
		MoveTimer += DeltaTime;

		float TelegraphPct = GetTelegraphPercentage();
		float MovePct = GetMovePercentage();

		if (MovePct > 0.f)
		{
			if (Enemy.Mesh.CanRequestLocomotion())
			{
				FHazeRequestLocomotionData Request;
				Request.AnimationTag = n"CastleChessPiece";
				Request.SubAnimationTag = n"Move";

				Enemy.Mesh.RequestLocomotion(Request);
			}
		}
		else if (TelegraphPct > 0.f)
		{
			if (Enemy.Mesh.CanRequestLocomotion())
			{
				FHazeRequestLocomotionData Request;
				Request.AnimationTag = n"CastleChessPiece";
				Request.SubAnimationTag = n"Telegraph";

				Enemy.Mesh.RequestLocomotion(Request);
			}
		}

		float TelegraphValue = TelegraphPct;
		if (TelegraphCurve != nullptr)
			TelegraphValue = TelegraphCurve.GetFloatValue(TelegraphValue);
		TelegraphUpdate(TelegraphValue);

		if (!bTelegraphStarted && TelegraphPct > 0.f)
		{
			bTelegraphStarted = true;
			TelegraphStart();
		}

		if (!bTelegraphDone && TelegraphPct >= 1.f)
		{
			TelegraphDone();
		}

		float RotationPct = TelegraphPct;
		// if (TelegraphRotationCurve != nullptr)
		// 	RotationPct = TelegraphRotationCurve.GetFloatValue(TelegraphPct);

		float VerticalPct = 0.f;
		if (VerticalMoveCurve != nullptr)
			VerticalPct = VerticalMoveCurve.GetFloatValue(MovePct);

		float XPct = MovePct;
		if (LateralXMoveCurve != nullptr)
			XPct = LateralXMoveCurve.GetFloatValue(MovePct);

		float YPct = MovePct;
		if (LateralYMoveCurve != nullptr)
			YPct = LateralYMoveCurve.GetFloatValue(MovePct);

		FVector NewLocation = OriginalPosition;
		NewLocation += XMovement * XPct;
		NewLocation += YMovement * YPct;
		NewLocation.Z += CurrentJumpHeight * VerticalPct;
		
		FVector DestinationPosition = OriginalPosition + XMovement + YMovement;
		
		if (MoveComp.CanCalculateMovement())
		{
			FVector FacingDirection = Owner.ActorForwardVector;
			FVector TargetFacingDirection = FacingDirection;
			if (!DestinationPosition.IsNear(OriginalPosition, 80.f))
				TargetFacingDirection = DestinationPosition - OriginalPosition;
			FRotator Rotation = FRotator::MakeFromX(Math::RotateVectorTowardsAroundAxis(FacingDirection, TargetFacingDirection, MoveComp.WorldUp, 180.f * DeltaTime));
			
			if (DeltaTime > 0.f)
				MoveComp.SetVelocity((NewLocation - MoveComp.OwnerLocation) / DeltaTime);
			MoveComp.SetControlledComponentTransform(NewLocation, Rotation);
		}
		if (MovePct >= 1.f)
		{
			if(VerticalPct > 0)
				Owner.SetCapabilityActionState(n"AudioLandedOnGround", EHazeActionState::ActiveForOneFrame);
			FinishMove();
		}
    }

	float GetMovePercentage()
	{
		if (bTelegraphBeforeMoving)
			return FMath::Clamp((MoveTimer - TelegraphDuration) / MoveDuration, 0.f, 1.f);
		else
		{
			float Delta = FMath::Max(TelegraphDuration - MoveDuration, 0.f);
			if (MoveTimer < Delta)
				return 0.f;
			
			return FMath::Clamp((MoveTimer - Delta) / MoveDuration, 0.f, 1.f);
		}
	}

	float GetTelegraphPercentage()
	{
		if (bTelegraphBeforeMoving)
			return FMath::Clamp(MoveTimer / TelegraphDuration, 0.f, 1.f);
		else
		{
			float Delta = FMath::Max(MoveDuration - TelegraphDuration, 0.f);
			if (MoveTimer < Delta)
				return 0.f;
			
			return FMath::Clamp((MoveTimer - Delta) / TelegraphDuration, 0.f, 1.f);
		}
	}
};