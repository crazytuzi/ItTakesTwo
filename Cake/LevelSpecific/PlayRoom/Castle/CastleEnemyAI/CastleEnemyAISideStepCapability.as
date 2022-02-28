import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAISideStepCapability : UCharacterMovementCapability
{
    default TickGroupOrder = 50;
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyAbility");

    // Minimum cooldown for the sidestep
    UPROPERTY()
    float SideStepCooldownMin = 1.f;

    // Maximum cooldown for the sidestep
    UPROPERTY()
    float SideStepCooldownMax = 8.f;

    // Distance to sidestep
    UPROPERTY()
    float SideStepDistance = 300.f;

    ACastleEnemy Enemy;
    float CooldownTimer = 0.f;
    float CancelTimer = 0.f;
    FVector TargetPosition;
    bool bReachedTarget = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		Super::Setup(Params);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (Enemy.AggroedPlayer != nullptr && CooldownTimer <= 0.f)
            return EHazeNetworkActivation::ActivateUsingCrumb; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (bReachedTarget)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Owner.BlockCapabilities(n"CastleEnemyAI", this);
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);

        CooldownTimer = FMath::RandRange(SideStepCooldownMin, SideStepCooldownMax);

        FVector Offset = FMath::VRand(); 
        Offset.Z = 0.f;
        Offset *= SideStepDistance;

        TargetPosition = Enemy.ActorLocation + Offset;
        bReachedTarget = false;
        CancelTimer = 0.f;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"CastleEnemyAI", this);
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if (Enemy.AggroedPlayer != nullptr && CooldownTimer >= 0)
            CooldownTimer -= DeltaTime;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!MoveComp.CanCalculateMovement())
            return;

        CancelTimer += DeltaTime;
        if (CancelTimer >= (SideStepDistance / Enemy.MovementSpeed))
            bReachedTarget = true;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemySideStep");

		if (HasControl())
		{
			FVector ToTarget = TargetPosition - Enemy.ActorLocation;
			ToTarget.Z = 0.f;

			float CurDistance = ToTarget.Size();
			if (CurDistance < 0.01)
				bReachedTarget = true;

			float MoveDistance = FMath::Min(DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier, CurDistance);
			FVector DeltaMove = ToTarget.GetSafeNormal() * MoveDistance;
			Movement.ApplyDelta(DeltaMove);

			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();

			AHazePlayerCharacter FacingPlayer = Enemy.AggroedPlayer;
			if (FacingPlayer != nullptr)
			{
				FVector ToPlayer = FacingPlayer.ActorLocation - Enemy.ActorLocation;
				ToPlayer.Z = 0.f;
				MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToPlayer.GetSafeNormal()), Enemy.FacingRotationSpeed);
			}
			else
			{
				MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), Enemy.FacingRotationSpeed);
			}
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

        Movement.ApplyTargetRotationDelta();
		Movement.FlagToMoveWithDownImpact();

		MoveComp.Move(Movement);

		Enemy.SendMovementAnimationRequest(Movement, n"Movement", NAME_None);
    }

};