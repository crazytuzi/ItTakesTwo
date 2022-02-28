import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;


class UWallWalkingAnimalFallOffWallCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AWallWalkingAnimal TargetAnimal;
	UWallWalkingAnimalMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	const float LeaveWallAmount = 600.f;

	FVector CurrentWallNormal;
	float MoveOutAmountLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
		MoveComp = UWallWalkingAnimalMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.StandingOnPrupleGuckTime <= TargetAnimal.MaxStandOnGuckTime)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(!TargetAnimal.bFallingOffWall)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		MoveOutAmountLeft = LeaveWallAmount;
		CurrentWallNormal = MoveComp.WorldUp;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetAnimal.bFallingOffWall = true;
		TargetAnimal.SetCapabilityActionState(n"AudioSpiderSlideOffSap", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WallWalkingAnimal_FallOffGuck");
		if(HasControl())
		{
			const float MoveOutSpeed = 400.f;
			
			float MoveAmount = FMath::Min(MoveOutAmountLeft, MoveOutSpeed * DeltaTime);
			MoveOutAmountLeft -= MoveAmount;
			MoveData.ApplyDelta(CurrentWallNormal * MoveAmount);
			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();
			MoveCharacter(MoveData, n"Movement");
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			MoveCharacter(MoveData, n"Movement");
		}
	}

	void MoveCharacter(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = NAME_None)
    {
        if(AnimationRequestTag != NAME_None)
        {
           TargetAnimal.SendMovementAnimationRequest(MoveData, FVector::ZeroVector, AnimationRequestTag, SubAnimationRequestTag);
        }
        MoveComp.Move(MoveData);
    }
}
