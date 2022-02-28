import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemySpawner;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Spline.SplineComponent;

class UCastleEnemyAISpawnLoiterCapability : UCharacterMovementCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 10;
    default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

    ACastleEnemy Enemy;

    bool bReachedFunnel = false;
	FVector FunnelPosition;
    FVector LoiterPosition;
	float FunnelTimer = 0.f;

	UHazeSplineComponent LoiterSpline;
	float SplineDistance = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		Super::Setup(Params);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (!IsActioning(n"SpawnLoiter"))
            return EHazeNetworkActivation::DontActivate; 
        return EHazeNetworkActivation::ActivateUsingCrumb; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (Enemy.AggroedPlayer != nullptr && bReachedFunnel)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
        if (!IsActioning(n"SpawnLoiter"))
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"CastleEnemyAI", this);
        bReachedFunnel = false;
		FunnelTimer = 0.f;

		ConsumeAttribute(n"SpawnFunnelPosition", FunnelPosition);
		ConsumeAttribute(n"SpawnLoiterPosition", LoiterPosition);

		UObject SplineObject;
		ConsumeAttribute(n"SpawnLoiterSpline", SplineObject);
		LoiterSpline = Cast<UHazeSplineComponent>(SplineObject);
		SplineDistance = 0.f;

		UObject AnimObject;
		ConsumeAttribute(n"SpawnAnimation", AnimObject);

		if (AnimObject != nullptr)
		{
			Enemy.PlaySlotAnimation(Animation = Cast<UAnimSequence>(AnimObject), BlendTime = 0.f,
				OnBlendingOut = FHazeAnimationDelegate(this, n"SpawnAnimDone"));

			Enemy.Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
			
			Enemy.SetActorEnableCollision(false);
			Enemy.SetActorHiddenInGame(false);
			Enemy.Mesh.HazeForceUpdateAnimation();
		}

		Enemy.BlockAutoDisable(true);
		Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
    }

	UFUNCTION()
	void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase Mesh)
	{
		FHazeLocomotionTransform Transform;
		Mesh.ConsumeLastExtractedRootMotion(Transform);

		Owner.AddActorWorldOffset(Transform.DeltaTranslation);
		Owner.AddActorWorldRotation(Transform.DeltaRotation);
	}

	UFUNCTION()
	void SpawnAnimDone()
	{
		Enemy.SetActorEnableCollision(true);

		Enemy.Mesh.OnPostAnimEvalComplete.UnbindObject(this);
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		ConsumeAction(n"SpawnLoiter");

		Enemy.SetActorHiddenInGame(false);
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
        if (!bReachedFunnel)
            Owner.UnblockCapabilities(n"CastleEnemyAI", this);

		if (!IsActioning(n"SpawnLoiter") && Enemy.HasActorBegunPlay())
			Enemy.BlockAutoDisable(false);

		Enemy.SetLeashPosition(LoiterPosition, FRotator::MakeFromX((LoiterPosition - FunnelPosition).GetSafeNormal()));
		Enemy.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Block);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!MoveComp.CanCalculateMovement())
            return;
		if (Enemy.IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
			return;

		if (Enemy.AggroedPlayer != nullptr && bReachedFunnel)
			ConsumeAction(n"SpawnLoiter");

		FunnelTimer += DeltaTime;

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyAISpawnLoiter");

		if (HasControl())
		{
			FVector TargetPosition;
			if (!bReachedFunnel)
			{
				TargetPosition = FunnelPosition;
			}
			else if(LoiterSpline != nullptr)
			{
				FVector ClosestWorldPos;
				LoiterSpline.FindDistanceAlongSplineAtWorldLocation(Enemy.ActorLocation, ClosestWorldPos, SplineDistance);
				SplineDistance += Enemy.MovementSpeed * DeltaTime * Enemy.MovementMultiplier;

				TargetPosition = LoiterSpline.GetLocationAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
			}
			else
			{
				TargetPosition = LoiterPosition;
			}

			TargetPosition.Z = Enemy.ActorLocation.Z;

			FVector ToTarget = TargetPosition - Enemy.ActorLocation;
			float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

			if (TargetDistance < FMath::Max(20.f, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier))
			{
				if (!bReachedFunnel)
				{
					bReachedFunnel = true;
					Owner.UnblockCapabilities(n"CastleEnemyAI", this);
				}
				else if (LoiterSpline == nullptr)
				{
					ConsumeAction(n"SpawnLoiter");
				}

				if (LoiterSpline != nullptr && SplineDistance >= LoiterSpline.GetSplineLength())
					LoiterSpline = nullptr;
			}

			FVector MoveDirection = ToTarget / TargetDistance;
			float MoveDistance = FMath::Min(TargetDistance, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier);

			FVector DeltaMove = MoveDirection * MoveDistance;
			Movement.ApplyDelta(DeltaMove);

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

			if (!bReachedFunnel)
			{
				FVector TargetPosition = FunnelPosition;
				TargetPosition.Z = Enemy.ActorLocation.Z;

				FVector ToTarget = TargetPosition - Enemy.ActorLocation;
				float TargetDistance = FMath::Max(ToTarget.Size(), 0.01f);

				if (TargetDistance < FMath::Max(20.f, DeltaTime * Enemy.MovementSpeed * Enemy.MovementMultiplier))
				{
					bReachedFunnel = true;
					Owner.UnblockCapabilities(n"CastleEnemyAI", this);
				}
			}
		}

		Movement.OverrideCollisionProfile(n"EnemyIgnoreEnemy");
		MoveComp.Move(Movement);

		Enemy.SendMovementAnimationRequest(Movement, n"Movement", NAME_None);

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();
    }
};