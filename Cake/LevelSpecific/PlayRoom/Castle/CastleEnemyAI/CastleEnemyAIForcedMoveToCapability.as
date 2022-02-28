import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;

class UCastleEnemyAIForcedMoveToCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 10;
    default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

    ACastleEnemy Enemy;
    UHazeBaseMovementComponent MoveComp;
    ACastleEnemySpawner Spawner;

	FVector MoveDestination;
	bool bReachedDestination = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (GetAttributeVector(n"EnemyForceMoveTo") == FVector::ZeroVector)
            return EHazeNetworkActivation::DontActivate; 
        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (bReachedDestination)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        ConsumeAttribute(n"EnemyForceMoveTo", MoveDestination);

        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
        Owner.BlockCapabilities(n"CastleEnemyAI", this);
		bReachedDestination = false;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"CastleEnemyAI", this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!MoveComp.CanCalculateMovement())
            return;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyAIForcedMoveTo");

        FVector TargetPosition = MoveDestination;
        TargetPosition.Z = Enemy.ActorLocation.Z;

        FVector ToTarget = TargetPosition - Enemy.ActorLocation;
        float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

        if (TargetDistance < 1.f)
			bReachedDestination = true;

        FVector MoveDirection = ToTarget / TargetDistance;
        float MoveDistance = FMath::Min(TargetDistance, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier);

        FVector DeltaMove = MoveDirection * MoveDistance;
        Movement.ApplyDelta(DeltaMove);

        MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), Enemy.FacingRotationSpeed);

        Movement.ApplyTargetRotationDelta();
		Movement.ApplyGravityAcceleration();
		Movement.ApplyActorVerticalVelocity();
		Movement.FlagToMoveWithDownImpact();
		Movement.OverrideCollisionProfile(n"EnemyIgnoreEnemy");
		MoveComp.Move(Movement);

		Enemy.SendMovementAnimationRequest(Movement, n"Movement", NAME_None);
    }
};