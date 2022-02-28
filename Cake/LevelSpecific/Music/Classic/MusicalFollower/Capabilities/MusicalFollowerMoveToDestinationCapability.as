import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Vino.Movement.Components.MovementComponent;

class MusicalFollowerMoveToDestinationCapability : UHazeCapability
{
	AMusicalFollower Follower;
	USteeringBehaviorComponent Steering;
	UHazeCrumbComponent CrumbComp;

	bool bCloseEnoughToTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Follower = Cast<AMusicalFollower>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Follower.bMoveToTargetDestination)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(bCloseEnoughToTarget)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(Steering.Follow.FollowTarget == nullptr)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Follower.ResetFollowLocalOffset();
		Owner.BlockCapabilities(n"MusicalFollowerMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.SetActorLocationAndRotation(Steering.Follow.FollowTarget.ActorLocation, Steering.Follow.FollowTarget.ActorRotation);
		Follower.HandleReachedTargetDestination();
		Follower.bMoveToTargetDestination = false;
		Owner.UnblockCapabilities(n"MusicalFollowerMovement", this);
		Steering.DisableAllBehaviors();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bCloseEnoughToTarget)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(!Follower.bMoveToTargetDestination)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat FacingRotation;
		CalculateFrameMove(FacingRotation, DeltaTime);
	}

	void CalculateFrameMove(FQuat& NewFacingRotation, float DeltaTime)
	{
		if(HasControl())
		{
			const float DistanceMinimum = 1500.0f;
			const float DistanceMinimumToAttach = 10.0f;
			const float DistanceToTarget = Steering.FollowLocation.Distance(Owner.ActorLocation);
			float DistanceMultiplier = 1.0f;

			if(DistanceToTarget < DistanceMinimum)
			{
				DistanceMultiplier = DistanceToTarget / DistanceMinimum;

				if(DistanceToTarget < DistanceMinimumToAttach)
				{
					bCloseEnoughToTarget = true;
				}

				const FQuat NewRotation = FMath::QInterpConstantTo(Owner.ActorRotation.Quaternion(), Steering.Follow.FollowTarget.ActorRotation.Quaternion(), DeltaTime, 2.0f);
				Owner.SetActorRotation(NewRotation);
			}
			else
			{
				const FQuat NewRotation = FMath::QInterpConstantTo(Owner.ActorRotation.Quaternion(), Steering.DirectionToTarget.ToOrientationQuat(), DeltaTime, 2.0f);
				Owner.SetActorRotation(NewRotation);
			}

			FVector Delta = Steering.DirectionToTarget * (Follower.MoveToDestinationSpeed * DistanceMultiplier) + Follower.AcceleratedOffset.Value;

			Owner.AddActorWorldOffset(Delta * DeltaTime);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Owner.SetActorLocationAndRotation(ConsumedParams.Location, ConsumedParams.Rotation);
		}

		NewFacingRotation = Steering.DirectionToTargetLocation.ToOrientationQuat();
	}
}
