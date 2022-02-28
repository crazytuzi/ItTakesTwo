import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;


class USickleEnemyUnderGroundMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyUnderGround");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;
	UHazeCrumbComponent CrumbComp;

	FVector TargetLocation;
	bool bWasMovingToTargetLocationLastFrame = false;
	float ChangeTargetAtDistance = 0;
	bool bIsShowingHead = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(AiOwner);
		CrumbComp = UHazeCrumbComponent::Get(AiOwner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChangeTargetLocation();
		AiOwner.CapsuleComponent.SetCollisionProfileName(Trace::GetCollisionProfileName(AiComponent.UnderGroundMovementProfile));
		AiComponent.IgnorePlayersWhenMoving();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bIsShowingHead = false;
		AiComponent.RemoveMeshOffsetInstigator(this);	
		AiComponent.IncludePlayersWhenMoving();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyUnderGroundMovement");
		FinalMovement.OverrideStepDownHeight(50.f);

		if(HasControl())
		{
			// if(!AiComponent.IsGrounded())
			// {
			// 	FinalMovement.ApplyActorVerticalVelocity();
			// 	FinalMovement.ApplyGravityAcceleration();
			// }

			AHazePlayerCharacter CurrentTarget = AiOwner.GetCurrentTarget();
			
			if(AiOwner.CanMove())
			{
				if(bIsShowingHead)
				{
					AiComponent.RemoveMeshOffsetInstigator(this);
					bIsShowingHead = false;
				}
					
				// if(CurrentTarget != nullptr)
				// {
				// 	bWasMovingToTargetLocationLastFrame = false;
				// 	UpdateAttackTargetMovement(DeltaTime, CurrentTarget, FinalMovement);
				// }
				if(AiOwner.AreaToMoveIn != nullptr)
				{
				// Find a random location in the valid area to fly to
					if(bWasMovingToTargetLocationLastFrame == false)
					{
						bWasMovingToTargetLocationLastFrame = true;
						ChangeTargetLocation();
					}

					UpdateNormalMovement(DeltaTime, FinalMovement);
				}
				else
				{
					PrintWarning("" + AiOwner.GetName() + " has no moveable area", 0);
				}
			}

			if(AiComponent.Velocity.IsNearlyZero())
			{
				if(AiOwner.GetActorForwardVector().DotProduct(AiComponent.GetTargetFacingRotation().Vector()) > 0.99f)
				{		
					AiComponent.SetTargetFacingRotation(FRotator(0.f, FMath::RandRange(0.f, 360.f), 0.f), FMath::RandRange(1.f, 3.f));
				}

				FinalMovement.ApplyTargetRotationDeltaWithoutConstantSpeed();
			}
			else
			{
				FinalMovement.ApplyTargetRotationDelta();
			}

			if(AiComponent.CanCalculateMovement())
			{
				AiComponent.Move(FinalMovement);
				AiOwner.CrumbComponent.LeaveMovementCrumb();
			}

		}
		// Remote
		else if(AiComponent.CanCalculateMovement())
		{
			const bool bIsMoving = AiComponent.GetVelocity().SizeSquared() > 1;
			if(bIsMoving && bIsShowingHead)
			{
				AiComponent.RemoveMeshOffsetInstigator(this);
				bIsShowingHead = false;
			}
			else if(!bIsMoving && !bIsShowingHead)
			{
				AiComponent.ShowHead(this);
				bIsShowingHead = true;
			}

			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);
			AiComponent.Move(FinalMovement);
		}
	}

	void ChangeTargetLocation(int Iteration = 0)
	{
		FVector WantedTargetLocation = AiOwner.GetActorLocation();
		if(AiOwner.GetRandomLocationInShape(WantedTargetLocation, AiComponent.StrayFromHomeDistance, true))
			TargetLocation = WantedTargetLocation;
		ChangeTargetAtDistance = AiComponent.PickNewMovetoLocationDistance.GetRandomValue();

		FVector DirToTarget = TargetLocation - AiOwner.GetActorLocation();
		DirToTarget = DirToTarget.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		
		float BlockMovementTime = AiComponent.StayAtReachedTargetTime.GetRandomValue();
		AiOwner.BlockMovement(BlockMovementTime);

		AiComponent.ShowHead(this);
		bIsShowingHead = true;
	}

	void UpdateNormalMovement(float DeltaTime, FHazeFrameMovement& FrameMovement)
	{
		float MovementSpeed = AiComponent.MovementSpeed;

		// If we have reached the current moveto target, pick a new one
		const float DistanceToTarget = AiOwner.GetActorLocation().Dist2D(TargetLocation, AiComponent.WorldUp);
		if(DistanceToTarget - ChangeTargetAtDistance < MovementSpeed * DeltaTime || DistanceToTarget < ChangeTargetAtDistance)
		{
			ChangeTargetLocation();
		}
		else
		{
			// Move to the current active target
			const FVector DiffToTarget = (TargetLocation - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp);
			const FVector DirToTarget = DiffToTarget.GetSafeNormal();	
			AiComponent.SetTargetFacingDirection(DirToTarget, AiComponent.MovementRotationSpeed);
		}

		FrameMovement.ApplyVelocity(AiOwner.GetActorForwardVector() * MovementSpeed);
	}

	// void UpdateAttackTargetMovement(float DeltaTime, AHazePlayerCharacter Target, FHazeFrameMovement& FrameMovement)
	// {
	// 	const float MovementSpeed = AiComponent.MovementSpeed * AiComponent.RageMoveSpeedMultiplier;
	// 	const FVector DiffToTarget = (Target.GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp);
	// 	const FVector DirToTarget = DiffToTarget.GetSafeNormal();
	// 	const float DistanceToTarget = DiffToTarget.Size();

	// 	AiComponent.SetTargetFacingDirection(DirToTarget, 12.f);
	// 	if(DistanceToTarget > AiComponent.AttackDistance && DistanceToTarget > MovementSpeed * DeltaTime)
	// 	{	
	// 		FrameMovement.ApplyVelocity(AiOwner.GetActorForwardVector() * MovementSpeed);
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Debug = "";
		return Debug;
	}

}