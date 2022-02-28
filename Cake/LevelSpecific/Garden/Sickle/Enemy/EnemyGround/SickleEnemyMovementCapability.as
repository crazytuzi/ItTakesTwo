import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

class USickleEnemyMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Falling);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

  	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	USickleCuttableHealthComponent HealthComp;

	bool bWasMovingToTargetLocationLastFrame = false;
	float ChangeTargetAtDistance = 0;
	float AttackTime = 0;
	FVector TargetLocation;
	bool bHasKnockBack = false;
	bool bHasAppliedDeathRotation = false;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		HealthComp = AiOwner.SickleCuttableComp;
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
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AiOwner.InitializeMovementForNextFrame();
		
		// Force dead owner to the 
		if(!AiOwner.IsAlive())
		{
			if(!AiComponent.IsGrounded())
			{
				AiOwner.TotalCollectedMovement.ApplyActorHorizontalVelocity();
				AiOwner.TotalCollectedMovement.ApplyActorVerticalVelocity();
				AiOwner.TotalCollectedMovement.ApplyGravityAcceleration();
			}
			else if(!bHasAppliedDeathRotation && AiOwner.LastValidAttacker != EHazePlayer::MAX) 
			{
				bHasAppliedDeathRotation = true;
				FVector PlayerLocation = Game::GetPlayer(AiOwner.LastValidAttacker).GetActorLocation();
				FVector DirToPlayer = (PlayerLocation - AiOwner.GetActorLocation()).GetSafeNormal();
				AiComponent.SetTargetFacingDirection(DirToPlayer);
			}
		
			FHazeLocomotionTransform RootMotionTransform;
			AiOwner.Mesh.ConsumeLastExtractedRootMotion(RootMotionTransform);
			AiOwner.TotalCollectedMovement.ApplyRootMotion(RootMotionTransform);
			AiOwner.TotalCollectedMovement.ApplyTargetRotationDelta();

			AiComponent.Move(AiOwner.TotalCollectedMovement);
			
			// Reset movement for next frame 
			AiOwner.InitializeMovementForNextFrame(true);
			return;
		}
	
		if(IsDebugActive())
		{
			System::DrawDebugSphere(AiOwner.GetActorCenterLocation());
		}

		if(!AiComponent.IsGrounded())
			AiOwner.TotalCollectedMovement.OverrideStepDownHeight(1.f);

		float HorizontalImpactSizeSq = 0;
		float VerticalImpactSizeSq = 0;
		FSickleEnemyHit Impact;
		if(AiComponent.ConsumeHits(Impact))
		{	
			FVector HorizontalKnockBack = Impact.KnockBackAmount.ConstrainToPlane(FVector::UpVector);
			HorizontalKnockBack.Z = 0;

			HorizontalImpactSizeSq = HorizontalKnockBack.SizeSquared();
			if(HorizontalImpactSizeSq > 1)
			{
				bHasKnockBack = true;	
				AiOwner.MeshOffsetComponent.FreezeAndResetWithTime(Impact.KnockBackHorizontalMovementTime);
				AiOwner.TotalCollectedMovement.ApplyDeltaWithCustomVelocity(HorizontalKnockBack, FVector::ZeroVector);
			}

			// Only apply up amount if we are grounded so we cant keep on going up.
			if(AiComponent.IsGrounded())
			{
				const FVector VerticalKnockBack = Impact.KnockBackAmount.ConstrainToDirection(FVector::UpVector);
				VerticalImpactSizeSq = VerticalKnockBack.SizeSquared();
				if(VerticalImpactSizeSq > 1)
				{
					bHasKnockBack = true;	
					AiOwner.TotalCollectedMovement.ApplyVelocity(VerticalKnockBack);	
				}
			}
			
			AiOwner.ApplyStunnedDuration(Impact.StunnedDuration);	
		}

		if(bHasKnockBack)
		{	
			AiOwner.TotalCollectedMovement.OverrideStepDownHeight(1.f);
			if(HorizontalImpactSizeSq < 1.f && VerticalImpactSizeSq < 1.f)
			{
				if(AiComponent.IsGrounded())
				{
					bHasKnockBack = false;
				}		
				else
				{
					AiOwner.TotalCollectedMovement.ApplyActorVerticalVelocity();
					AiOwner.TotalCollectedMovement.ApplyGravityAcceleration();
				}
			}
		}
		
		if(HasControl())
		{		
			if(!bHasKnockBack)
			{
				if(!AiComponent.IsGrounded())
				{
					AiOwner.TotalCollectedMovement.ApplyActorVerticalVelocity();
					AiOwner.TotalCollectedMovement.ApplyGravityAcceleration();
				}

				if(AiComponent.IsGrounded() && AiOwner.CanMove())
				{	
					AHazePlayerCharacter CurrentTarget = AiOwner.GetCurrentTarget();
					if(CurrentTarget != nullptr)
					{
						bWasMovingToTargetLocationLastFrame = false;
						UpdateAttackTargetMovement(DeltaTime, AiOwner.TotalCollectedMovement, CurrentTarget);		
					}
					else if(AiOwner.AreaToMoveIn != nullptr)
					{
						if(bWasMovingToTargetLocationLastFrame == false)
						{
							bWasMovingToTargetLocationLastFrame = true;
							ChangeTargetLocation();
						}

						UpdateNormalMovement(DeltaTime, AiOwner.TotalCollectedMovement);
						AttackTime = 0;
					}
					else
					{
						PrintWarning("" + AiOwner.GetName() + " has no moveable area", 0);
					}
				}
			}	
	
			AiOwner.TotalCollectedMovement.ApplyTargetRotationDelta();
			AiComponent.Move(AiOwner.TotalCollectedMovement);
			AiOwner.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			// Always consume the trail
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			
			if(!bHasKnockBack)
			{
				AiOwner.TotalCollectedMovement.ApplyConsumedCrumbData(ReplicationData);
			}
		
			AiComponent.Move(AiOwner.TotalCollectedMovement);
		}

		// Reset movement for next frame 
		AiOwner.InitializeMovementForNextFrame(true);
    }

	void ChangeTargetLocation()
	{
		AiOwner.GetRandomLocationInShape(TargetLocation, AiComponent.StrayFromHomeDistance);
		ChangeTargetAtDistance = AiComponent.PickNewMovetoLocationDistance.GetRandomValue();
		AiOwner.BlockMovement(AiComponent.StayAtReachedTargetTime.GetRandomValue());
	}

	void UpdateNormalMovement(float DeltaTime, FHazeFrameMovement& FrameMovement)
	{
		const float MovementSpeed = AiComponent.MovementSpeed;
		const FVector MyLocation = AiOwner.GetActorLocation();
		const FVector2D CollisionSize = AiOwner.GetCollisionSize();
			
		// Update the movement toward the wanted moveto location
		const float DistanceToTarget = MyLocation.Dist2D(TargetLocation, AiComponent.WorldUp);
		if(DistanceToTarget < MovementSpeed * DeltaTime || DistanceToTarget < ChangeTargetAtDistance)
		{
			ChangeTargetLocation();
		}

		const FVector DiffToTarget = (TargetLocation - MyLocation).ConstrainToPlane(AiComponent.WorldUp);
		const FVector DirToTarget = DiffToTarget.GetSafeNormal();	
		AiComponent.SetTargetFacingDirection(DirToTarget, 4.f);
		FrameMovement.ApplyVelocity(AiOwner.GetActorForwardVector() * MovementSpeed);
	}

	void UpdateAttackTargetMovement(float DeltaTime, FHazeFrameMovement& FrameMovement, AHazePlayerCharacter Target)
	{
		const float MovementSpeed = AiComponent.AttackMovementSpeed.GetFloatValue(AttackTime, AiComponent.MovementSpeed);
		const FVector MyLocation = AiOwner.GetActorLocation();
		const FVector2D CollisionSize = AiOwner.GetCollisionSize();

		FVector AttackPosition = AiOwner.GetAttackLocation();
		//AttackPosition += FRotator(0.f, AiOwner.OffsetIndex * 30.f, 0.f).Vector() * 100;

		FVector DeltaToTarget = AttackPosition - MyLocation;
		FVector RealDeltaToTarget = (Target.GetActorLocation() - MyLocation).ConstrainToPlane(Target.GetMovementWorldUp());

		if(AiOwner.GetHorizontalDistanceTo(Target) - AiComponent.AttackDistance < 0)
			return;

		// Face the target
		if(RealDeltaToTarget.SizeSquared() > 1)
		{
			AiComponent.SetTargetFacingDirection(RealDeltaToTarget.GetSafeNormal(), 8.f);
		}

		// Move Toward the Target
		if(RealDeltaToTarget.GetSafeNormal().DotProduct(AiOwner.GetActorForwardVector()) > 0.8f)
		{
			if(RealDeltaToTarget.Size() > MovementSpeed * DeltaTime)
			{
				FrameMovement.ApplyVelocity(RealDeltaToTarget.GetSafeNormal() * MovementSpeed);
			}
			else
			{
				FrameMovement.ApplyDelta(RealDeltaToTarget);
			}
		}
		
		AttackTime += DeltaTime;
	}
}