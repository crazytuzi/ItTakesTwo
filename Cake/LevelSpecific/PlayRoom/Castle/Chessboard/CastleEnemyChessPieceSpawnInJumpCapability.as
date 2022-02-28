import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

class UCastleEnemyChessPieceSpawnInJumpCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAI");

	// Curve used for lateral movement in board X in the jump
	UPROPERTY()
	UCurveFloat LateralXMoveCurve;

	// Curve used for lateral movement in board Y in the jump
	UPROPERTY()
	UCurveFloat LateralYMoveCurve;

	// Curve used for vertical movement in the jump
	UPROPERTY()
	UCurveFloat VerticalMoveCurve;

    ACastleEnemy Enemy;
    UHazeBaseMovementComponent MoveComp;
	UChessPieceComponent PieceComp;

	float JumpHeight = 0.f;
	float JumpDuration = 1.f;
	EChessPieceState StateAfterJump = EChessPieceState::Fighting;

	float MoveTimer = 0.f;

	FVector OriginalPosition;
	FVector MoveDestination;
	FVector XMovement;
	FVector YMovement;
	FVector2D DestinationGridPos;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);

		PieceComp.OnJumpIn.AddUFunction(this, n"OnPieceJumpIn");
    }

	UFUNCTION()
	void OnPieceJumpIn(ACastleEnemy Enemy, AChessboard Chessboard, FVector WorldPosition, float InJumpHeight, float InJumpDuration, EChessPieceState InStateAfterJump = EChessPieceState::Fighting)
	{
		PieceComp.State = EChessPieceState::JumpingIn;
		MoveDestination = WorldPosition;
		JumpHeight = InJumpHeight;
		JumpDuration = InJumpDuration;
		StateAfterJump = InStateAfterJump;
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (PieceComp.Chessboard == nullptr)
			return EHazeNetworkActivation::DontActivate; 
		if (PieceComp.State != EChessPieceState::JumpingIn)
			return EHazeNetworkActivation::DontActivate; 
		return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (PieceComp.Chessboard == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
		if (PieceComp.State != EChessPieceState::JumpingIn)
			return EHazeNetworkDeactivation::DeactivateLocal; 
		return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"CastleEnemyKnockback", this);

		DestinationGridPos = PieceComp.GridPosition;
		OriginalPosition = Enemy.ActorLocation;
		MoveTimer = 0.f;

		XMovement = (MoveDestination - Enemy.ActorLocation).ProjectOnTo(PieceComp.Chessboard.GetXVector());
		YMovement = (MoveDestination - Enemy.ActorLocation) - XMovement;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"CastleEnemyKnockback", this);
    }

	void FinishMove()
	{
		PieceComp.LandOnPosition(DestinationGridPos);
		PieceComp.State = StateAfterJump;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		UpdateMove(DeltaTime);

		if (Enemy.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleChessPiece";
			Request.SubAnimationTag = n"JumpIn";

			Enemy.Mesh.RequestLocomotion(Request);
		}
	}

	void UpdateMove(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		MoveTimer += DeltaTime;
		float MovePct = FMath::Clamp(MoveTimer / JumpDuration, 0.f, 1.f);

		float VerticalPct = 0.f;
		if (VerticalMoveCurve != nullptr)
			VerticalPct = VerticalMoveCurve.GetFloatValue(MovePct);
		else
			VerticalPct = FMath::Sqrt(FMath::Clamp(MovePct > 0.5f ? (2.f - (MovePct * 2.f)) : (MovePct * 2.f), 0.f, 1.f));

		float XPct = MovePct;
		if (LateralXMoveCurve != nullptr)
			XPct = LateralXMoveCurve.GetFloatValue(MovePct);

		float YPct = MovePct;
		if (LateralYMoveCurve != nullptr)
			YPct = LateralYMoveCurve.GetFloatValue(MovePct);

		FVector NewLocation = OriginalPosition;
		NewLocation += XMovement * XPct;
		NewLocation += YMovement * YPct;
		NewLocation.Z += JumpHeight * VerticalPct;

		Enemy.ActorLocation = NewLocation;

		if (MovePct >= 1.f)
			FinishMove();
    }
};