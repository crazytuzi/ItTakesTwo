
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;


class USickleEnemyAirMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

  	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;

	FVector TargetLocation;
	float ChangeTargetAtDistance = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		// 3 times for better random
		int Rounds = 3;
		while(Rounds > 0)
		{
			Rounds--;
			ChangeTargetLocation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyAirMovement");
		FinalMovement.OverrideStepDownHeight(0.f);

		if(IsDebugActive())
		{
			FLinearColor Color = HasControl() ? FLinearColor::Blue : FLinearColor::White;
			System::DrawDebugSphere(AiOwner.GetActorLocation(), LineColor = Color);
		}

		if(HasControl())
		{
			FVector FacingDirection = AiOwner.GetActorForwardVector();
			float FaceRotationSpeed = AiComponent.MovementRotationSpeed;


			if(AiOwner.bIsTakingSickleDamage)
			{
				const FVector DiffToTarget = (Game::GetMay().GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp);
				if(!DiffToTarget.IsNearlyZero())
				{
					FacingDirection = DiffToTarget.GetSafeNormal();
					FaceRotationSpeed = 0;
				}
			}

			if(AiOwner.CanMove())
			{
				const float MovementSpeed = AiComponent.MovementSpeed;

				// Get the air location we should have
				FVector WantedFlyLocation = AiOwner.GetActorLocation();
				AiComponent.ApplyFlyHeightMovement(DeltaTime, WantedFlyLocation, FinalMovement);
	
				// If we have reached the current moveto target, pick a new one
				FVector CurrentLocation = AiOwner.GetActorLocation();
				const float DistanceToTarget = CurrentLocation.Dist2D(TargetLocation, AiComponent.WorldUp);
				if(DistanceToTarget < MovementSpeed * DeltaTime || DistanceToTarget < ChangeTargetAtDistance)
				{
					ChangeTargetLocation();
				}
				else if(!AiOwner.bIsTakingSickleDamage && !AiOwner.bIsTakingWhipDamage)
				{
					// Move to the current active target
					const FVector DiffToTarget = (TargetLocation - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp);
					FacingDirection = DiffToTarget.GetSafeNormal();	
				}

				if(AiComponent.CurrentFlyHeight > AiComponent.FlyHeight - 50.f)
					FinalMovement.ApplyVelocity(AiOwner.GetActorForwardVector() * MovementSpeed);
			}

			AiComponent.SetTargetFacingDirection(FacingDirection, FaceRotationSpeed);
			FinalMovement.ApplyTargetRotationDelta();
			AiComponent.Move(FinalMovement);
			AiOwner.CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);
			AiComponent.Move(FinalMovement);
		}
	}

	void ChangeTargetLocation()
	{
		AiOwner.GetRandomLocationInShape(TargetLocation, AiComponent.StrayFromHomeDistance);
		ChangeTargetAtDistance = AiComponent.PickNewMovetoLocationDistance.GetRandomValue();
		AiOwner.BlockMovement(AiComponent.StayAtReachedTargetTime.GetRandomValue());
	}
}
