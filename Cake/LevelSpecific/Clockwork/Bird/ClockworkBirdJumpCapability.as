import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

class UClockworkBirdJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdJump");

	default CapabilityDebugCategory = n"ClockworkBirdJump";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AClockworkBird Bird;

	const float TimerMax = 0.7f;
	float CurrentTimer = 0.f;

	bool bShouldDeactivate = false;

	FVector HorizontalVelocity;

	// Movement Component
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		//Get ClockworkBird (owner)
		Bird = Cast<AClockworkBird>(Owner);
		
		//Setup MoveComp
		MoveComp = UHazeMovementComponent::Get(Bird);
		CrumbComp = UHazeCrumbComponent::Get(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
    	if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkActivation::DontActivate;
		
		if (!Bird.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ClockworkBirdTags::ClockworkBirdJumping)) 
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bShouldDeactivate) 			
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.bIsJumping = true;
		HorizontalVelocity = MoveComp.GetVelocity();
		ConsumeAction(ClockworkBirdTags::ClockworkBirdJumping);
		Bird.DidSecondJump(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.bIsJumping = false;
		bShouldDeactivate = false;
		CurrentTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Jump");

		if(HasControl())
		{	
			FVector VerticalVelocity = MoveComp.WorldUp * 1000.f;
			FVector CombinedVelocity = FVector(HorizontalVelocity + VerticalVelocity);

			MoveData.ApplyVelocity(CombinedVelocity);
			MoveData.OverrideStepUpHeight(0.f);
			MoveData.OverrideStepDownHeight(0.f);
			MoveData.ApplyGravityAcceleration();
			MoveData.ApplyTargetRotationDelta();
			MoveData.ApplyAndConsumeImpulses();

			MoveComp.Move(MoveData);
			CrumbComp.LeaveMovementCrumb();

			CurrentTimer += DeltaTime;
			if (CurrentTimer >= TimerMax)
			{
				bShouldDeactivate = true;
			}
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			MoveComp.Move(MoveData);
		}
	}
}