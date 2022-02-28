import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Vino.Movement.Components.MovementComponent;

event void FOnMusicalFollowerReachedTargetDestination();
event void FOnMusicalFollowerFoundTargetDestination(AMusicalFollower Follower);

class AMusicalFollower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMoveFollowerAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReachTargetLocationAudioEvent;

	UPROPERTY()
	FOnMusicalFollowerReachedTargetDestination OnReachedTargetDestination;

	UPROPERTY()
	FOnMusicalFollowerFoundTargetDestination OnFoundTargetDestination;

	UPROPERTY(DefaultComponent, Attach = Capsule, ShowOnActor)
	USteeringBehaviorComponent SteeringBehavior;
	default SteeringBehavior.Follow.FollowDistance = 300.0f;
	default SteeringBehavior.Follow.Size = 5000.0f;

	UPROPERTY(Category = Objective)
	AHazeActor TargetLocationActor;

	// The speed the actor will have when moving towards a target destination.
	UPROPERTY(Category = Objective)
	float MoveToDestinationSpeed = 2000.0f;

	// The follower will begin flying toward the target location when within this distance.
	UPROPERTY(Category = Objective)
	float DistanceMinimum = 6000.0f;

	// Time it takes to reach the follow location calculated by steering behavior.
	UPROPERTY(Category = Movement)
	float DistanceLag = 0.5f;

	UPROPERTY(Category = Movement, meta = (ClampMin = 0.01, ClampMax = 0.99))
	float ImpulseFriction = 0.7f;

	bool bMoveToTargetDestination = false;

	UPROPERTY(Category = Movement)
	bool bRotateTowardsFollowTarget = true;

	UPROPERTY(Category = Movement, meta = (EditCondition = "bRotateTowardsFollowTarget", EditConditionHides))
	float RotationTowardsTargetLag = 0.5f;

	private FVector ImpulseOffset;
	FHazeAcceleratedVector AcceleratedOffset;

	// If you select none or both, May will be selected.
	UPROPERTY()
	EHazeSelectPlayer PlayerToFollow = EHazeSelectPlayer::Cody;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	float FollowerVelocity;

	UFUNCTION(BlueprintCallable)
	void ResetFollowLocalOffset()
	{
		SteeringBehavior.Follow.LocalOffset = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateFollower()
	{
		if(PlayerToFollow == EHazeSelectPlayer::Cody)
		{
			SetActivateFollower(Game::GetCody());
		}
		else
		{
			SetActivateFollower(Game::GetMay());
		}
	}

	void SetActivateFollower(AHazeActor NewTargetToFollow)
	{
		if(HasControl() && !NewTargetToFollow.HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Player", NewTargetToFollow);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"HandleCrumbSetControlSide"), CrumbParams);
		}

		SetupFollower(NewTargetToFollow);
	}

	void AddToOffsetImpulse(FVector InImpulse)
	{
		ImpulseOffset += InImpulse;
	}

	UFUNCTION()
	private void HandleCrumbSetControlSide(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazeActor Player = Cast<AHazeActor>(CrumbData.GetObject(n"Player"));
		SetControlSide(Player);
	}

	private void SetupFollower(AHazeActor Player)
	{
		SteeringBehavior.bEnableFollowBehavior = true;
		SteeringBehavior.Follow.FollowTarget = Player;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"MusicalFollowerDistanceToTargetCapability");
		AddCapability(n"MusicalFollowerMoveToDestinationCapability");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ImpulseOffset *= FMath::Pow(ImpulseFriction, DeltaTime);
		AcceleratedOffset.AccelerateTo(ImpulseOffset, 0.5f, DeltaTime);
	}

	void HandleReachedTargetDestination()
	{
		OnReachedTargetDestination.Broadcast();
		HazeAkComp.HazePostEvent(ReachTargetLocationAudioEvent);
	}

	UFUNCTION()
	void MoveToTargetLocation()
	{
		HandleFoundTargetDestination();
		HazeAkComp.HazePostEvent(StartMoveFollowerAudioEvent);
		bMoveToTargetDestination = true;
		SteeringBehavior.Follow.FollowDistance = 1.0f;
		SteeringBehavior.bEnableFollowBehavior = true;
		SteeringBehavior.Follow.FollowTarget = TargetLocationActor;
	}

	UFUNCTION()
	void TeleportToTargetLocation()
	{
		SteeringBehavior.DisableAllBehaviors();
		SteeringBehavior.Follow.FollowTarget = nullptr;
		SetActorLocationAndRotation(TargetLocationActor.GetActorLocation(), TargetLocationActor.GetActorRotation());
	}

	void HandleFoundTargetDestination()
	{
		OnFoundTargetDestination.Broadcast(this);
	}
}
