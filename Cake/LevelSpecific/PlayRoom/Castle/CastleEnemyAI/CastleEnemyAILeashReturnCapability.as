import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAILeashReturnCapability : UCharacterMovementCapability
{
    default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 40;
    default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

    ACastleEnemy Enemy;
	float TimeWithoutAggroTarget = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		Super::Setup(Params);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate; 

		float DistanceSQ = Enemy.LeashFromPosition.DistSquared2D(Enemy.ActorLocation);
		if (Enemy.LeashRange > 0.f && DistanceSQ > FMath::Square(Enemy.LeashRange))
			return EHazeNetworkActivation::ActivateUsingCrumb; 

		if (Enemy.LeashReturnTimer > 0.f && DistanceSQ > 100.f && TimeWithoutAggroTarget >= Enemy.LeashReturnTimer)
			return EHazeNetworkActivation::ActivateUsingCrumb; 

		return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		float DistanceSQ = Enemy.LeashFromPosition.DistSquared2D(Enemy.ActorLocation);
		if (DistanceSQ > 100.f)
			return EHazeNetworkDeactivation::DontDeactivate; 

		if (!Enemy.LeashPositionRotation.Equals(Enemy.ActorRotation))
			return EHazeNetworkDeactivation::DontDeactivate; 

		return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		Enemy.ClearAggro();
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
		if (Enemy.AggroedPlayer == nullptr
			|| Enemy.LeashFromPosition.DistSquared2D(Enemy.AggroedPlayer.ActorLocation) > FMath::Square(Enemy.LeashRange))
		{
			TimeWithoutAggroTarget += DeltaTime;
		}
		else
		{
			TimeWithoutAggroTarget = 0.f;
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyLeashReturn");
		if (HasControl())
		{
			FVector ToTarget = Enemy.LeashFromPosition - Enemy.ActorLocation;
			ToTarget.Z = 0.f;

			float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

			FVector MoveDirection = ToTarget / TargetDistance;
			float MoveDistance = FMath::Min(TargetDistance, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier);

			FVector DeltaMove = MoveDirection * MoveDistance;
			Movement.ApplyDelta(DeltaMove);

			if (MoveDistance < 1.f)
				MoveComp.SetTargetFacingRotation(Enemy.LeashPositionRotation, Enemy.FacingRotationSpeed);
			else
				MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), Enemy.FacingRotationSpeed);

			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();
			Movement.ApplyTargetRotationDelta();
			Movement.FlagToMoveWithDownImpact();

		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		FVector PrevLocation = Enemy.ActorLocation;
		Movement.OverrideCollisionProfile(n"EnemyIgnoreEnemy");
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
    }
};