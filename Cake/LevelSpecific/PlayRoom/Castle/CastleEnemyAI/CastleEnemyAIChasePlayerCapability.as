import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAIChasePlayerCapability : UCharacterMovementCapability
{
    // Distance the enemy tries to achieve by chasing
    UPROPERTY()
    float MinimumDistance = 200.f;

    UPROPERTY()
    float InaccuracyDistance = 300.f;

    UPROPERTY()
    float InaccuracyAmount = 200.f;

    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

    ACastleEnemy Enemy;
	AHazePlayerCharacter ChasingPlayer;

    FVector CurrentInaccuracy;
	float BlockedByWallTimer = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		UCharacterMovementCapability::Setup(Params);
        Enemy = Cast<ACastleEnemy>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        if (Enemy.AggroedPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate; 

		if (Enemy.bChangeNetworkSideOnAggro && !Enemy.AggroedPlayer.HasControl())
			return EHazeNetworkActivation::DontActivate; 

		return EHazeNetworkActivation::ActivateUsingCrumb;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

        if (Enemy.AggroedPlayer == nullptr)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

        return EHazeNetworkDeactivation::DontDeactivate; 

    }
    UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"ChasingPlayer", Enemy.AggroedPlayer);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		ChasingPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"ChasingPlayer"));
		Enemy.SetCapabilityActionState(n"AudioStartedAggro", EHazeActionState::ActiveForOneFrame);
		BlockedByWallTimer = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
        CurrentInaccuracy = FVector::ZeroVector;
		ChasingPlayer = nullptr;
		Enemy.SetCapabilityActionState(n"AudioStoppedAggro", EHazeActionState::ActiveForOneFrame);
    }

	FVector LeashConstrainDelta(FVector DeltaMove)
	{
		FVector TargPos = Enemy.ActorLocation + DeltaMove;
		float LeashDist = TargPos.DistSquared(Enemy.LeashFromPosition);
		if (LeashDist < FMath::Square(Enemy.LeashMaxMovement))
			return DeltaMove;

		TargPos = Enemy.LeashFromPosition + ((TargPos - Enemy.LeashFromPosition) * (Enemy.LeashMaxMovement / FMath::Sqrt(LeashDist)));
		return TargPos - Enemy.ActorLocation;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyChasePlayer");
		if (HasControl())
		{

			FVector ToTarget = ChasingPlayer.ActorLocation - Enemy.ActorLocation;
			ToTarget.Z = 0.f;

			float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

			if (TargetDistance > InaccuracyDistance)
			{
				if (CurrentInaccuracy.IsNearlyZero())
					CurrentInaccuracy = ToTarget.GetSafeNormal().CrossProduct(FVector::UpVector) * FMath::RandRange(-InaccuracyAmount, InaccuracyAmount);

				FVector TargetPosition = ChasingPlayer.ActorLocation + CurrentInaccuracy;

				ToTarget = TargetPosition - Enemy.ActorLocation;
				ToTarget.Z = 0.f;

				float MoveDistance = DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier;
				FVector DeltaMove = ToTarget.GetSafeNormal() * MoveDistance;

				if (Enemy.LeashMaxMovement > 0.f)
					DeltaMove = LeashConstrainDelta(DeltaMove);
				Movement.ApplyDelta(DeltaMove);
			}
			else
			{
				FVector MoveDirection = ToTarget / TargetDistance;
				if (TargetDistance > MinimumDistance)
				{
					float MoveDistance = FMath::Min(TargetDistance, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier);

					FVector DeltaMove = MoveDirection * MoveDistance;
					if (Enemy.LeashMaxMovement > 0.f)
						DeltaMove = LeashConstrainDelta(DeltaMove);
					Movement.ApplyDelta(DeltaMove);
				}
			}

			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();
			Movement.ApplyTargetRotationDelta();
			Movement.FlagToMoveWithDownImpact();

			MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), Enemy.FacingRotationSpeed);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		FVector PrevLocation = Enemy.ActorLocation;
		MoveComp.Move(Movement);

		FVector ActualMovement = Enemy.ActorLocation - PrevLocation;

        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = ActualMovement;
        AnimationRequest.LocomotionAdjustment.WorldRotation = Movement.Rotation;
 		AnimationRequest.WantedVelocity = ActualMovement / DeltaTime;
        AnimationRequest.WantedWorldTargetDirection = Movement.MovementDelta;
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
		AnimationRequest.WantedVelocity.Z = 0.f;
		AnimationRequest.AnimationTag = n"Movement";
        Enemy.RequestLocomotion(AnimationRequest);

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();

		// If we've been blocked by static geometry for a while,
		// lose the aggro target.
		bool bBlockedByWall =
			ActualMovement.IsNearlyZero()
			&& MoveComp.ForwardHit.bBlockingHit
			&& MoveComp.ForwardHit.Component.Mobility == EComponentMobility::Static;

		if (bBlockedByWall)
		{
			BlockedByWallTimer += DeltaTime;
			if (BlockedByWallTimer > 2.f)
				Enemy.ClearAggro();
		}
		else
		{
			BlockedByWallTimer = 0.f;
		}
    }
};
