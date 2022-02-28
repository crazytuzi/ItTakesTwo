import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Queen.CastleEnemyQueenSpinAttack;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyQueenAbilitySpinAttack : UChessBossAbility
{
	default CapabilityTags.Add(n"QueenAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	TSubclassOf<ACastleEnemyQueenSpinAttack> SpinAttackType;
	ACastleEnemyQueenSpinAttack SpinAttackRef;

	FVector QueenStartGridPos;
	float StartYawValue;
	int RotationDirection = 1;

	UPROPERTY()
	FHazeTimeLike MoveToLocationTimelike;
	default MoveToLocationTimelike.Duration = 1;

	UPROPERTY()
	FHazeTimeLike RotateActorTimelike;
	default RotateActorTimelike.Duration = 12;

	UPROPERTY()
	FHazeTimeLike MoveBackFromLocationTimelike;
	default MoveBackFromLocationTimelike.Duration = 1;

	bool bAbilityFinished = false;
	default Cooldown = 12.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		if (SpinAttackType.IsValid())
		{
			SpinAttackRef = Cast<ACastleEnemyQueenSpinAttack>(SpawnActor(SpinAttackType, Owner.ActorLocation));
			SpinAttackRef.AttachToActor(Owner, AttachmentRule = EAttachmentRule::SnapToTarget);
		}

		MoveToLocationTimelike.BindUpdate(this, n"OnMoveToLocationTimelikeUpdate");
		MoveToLocationTimelike.BindFinished(this, n"OnMoveToLocationTimelikeFinished");

		RotateActorTimelike.BindUpdate(this, n"OnRotateActorTimelikeUpdate");
		RotateActorTimelike.BindFinished(this, n"OnRotateActorTimelikeFinished");

		MoveBackFromLocationTimelike.BindUpdate(this, n"OnMoveBackFromLocationTimelikeUpdate");
		MoveBackFromLocationTimelike.BindFinished(this, n"OnMoveBackFromLocationTimelikeFinished");
	}

	bool ShouldActivateAbility() const override
	{
		if (CurrentCooldown > 0.f)
			return false;

		return true;
	}

	bool ShouldDeactivateAbility() const override
	{
		if (bAbilityFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		bAbilityFinished = false;
		StartYawValue = Owner.ActorRotation.Yaw;

		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);

		QueenStartGridPos = Owner.ActorLocation;			
		MoveToLocationTimelike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AbilitiesComp.AbilityFinished();
		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);

		CurrentCooldown = Cooldown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}

	UFUNCTION()
    void OnMoveToLocationTimelikeUpdate(float CurrentValue)
    {
		FVector StartLocation = QueenStartGridPos;

		FVector2D CurrentGridPosition = PieceComp.GridPosition;
		FVector2D TargetGridPosition = CurrentGridPosition;

		float Distance = BIG_NUMBER;


		// NEW
		float Margin = 2.f;
		float MinGridLocation = Margin;
		float MaxGridLocation = PieceComp.Chessboard.GridSize.X - Margin - 1.f;

		
		if ((TargetGridPosition.X < MinGridLocation || TargetGridPosition.X > MaxGridLocation) && 
			(TargetGridPosition.Y >= MinGridLocation && TargetGridPosition.Y <= MaxGridLocation))
		{
			TargetGridPosition.X = FMath::Clamp(TargetGridPosition.X, MinGridLocation, MaxGridLocation);
		}
		else if ((TargetGridPosition.X >= MinGridLocation && TargetGridPosition.X <= MaxGridLocation) && 
				(TargetGridPosition.Y < MinGridLocation || TargetGridPosition.Y > MaxGridLocation))
		{
			TargetGridPosition.Y = FMath::Clamp(TargetGridPosition.Y, MinGridLocation, MaxGridLocation);
		}
		else if ((TargetGridPosition.X < MinGridLocation || TargetGridPosition.X > MaxGridLocation) && 
				(TargetGridPosition.Y < MinGridLocation || TargetGridPosition.Y > MaxGridLocation))
		{
			float OriginalX = TargetGridPosition.X;
			TargetGridPosition.X = FMath::Clamp(TargetGridPosition.X, MinGridLocation, MaxGridLocation);

			float AmountChanged = TargetGridPosition.X - OriginalX;

			if (TargetGridPosition.Y > MaxGridLocation)
				TargetGridPosition.Y -= FMath::Abs(AmountChanged);
			else
				TargetGridPosition.Y += FMath::Abs(AmountChanged);			
		}
		// END NEW


		FVector EndLocation = PieceComp.Chessboard.GetSquareCenter(TargetGridPosition);



		//FVector EndLocation = PieceComp.Chessboard.ActorLocation;

		Owner.SetActorLocation(FMath::Lerp(StartLocation, EndLocation, CurrentValue));
    }

	UFUNCTION()
    void OnMoveToLocationTimelikeFinished()
    {
		SpinAttackRef.EnableSpinAttack();
		RotateActorTimelike.PlayFromStart();
    }
	
	UFUNCTION()
    void OnRotateActorTimelikeUpdate(float CurrentValue)
    {
		float NewYawValue = StartYawValue + (360 * RotationDirection * CurrentValue * 2.f);
		Owner.SetActorRotation(FRotator(Owner.ActorRotation.Pitch, NewYawValue, Owner.ActorRotation.Roll));
    }

	UFUNCTION()
    void OnRotateActorTimelikeFinished()
    {
		SpinAttackRef.DisableSpinAttack();
		bAbilityFinished = true;		

		//MoveBackFromLocationTimelike.PlayFromStart();
    }

	UFUNCTION()
    void OnMoveBackFromLocationTimelikeUpdate(float CurrentValue)
    {
		FVector StartLocation = PieceComp.Chessboard.ActorLocation;
		FVector EndLocation = QueenStartGridPos;

		Owner.SetActorLocation(FMath::Lerp(StartLocation, EndLocation, CurrentValue));
    }
	
	UFUNCTION()
    void OnMoveBackFromLocationTimelikeFinished()
    {
		bAbilityFinished = true;		
    }

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SpinAttackRef.DestroyActor();
		SpinAttackRef = nullptr;
    }
}