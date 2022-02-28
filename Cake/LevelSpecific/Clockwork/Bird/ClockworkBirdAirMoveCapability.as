import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Vino.Movement.Components.MovementComponent;

class UClockworkBirdAirMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdAirMove");

	default CapabilityDebugCategory = n"ClockworkBirdAirMove";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 101;

	AClockworkBird Bird;

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
		
		if(Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkActivation::DontActivate;
        
		if (Bird.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (Bird.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.StopTimeline();
		
		Bird.BirdRoot.SetRelativeRotation(FRotator::ZeroRotator);
		Bird.BirdRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdAirMove");
		
		if(HasControl())
		{
			MoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Bird.PlayerInput, 400.f));		

			// Apply rotation from input
			FVector RotationVector = Bird.PlayerInput.GetSafeNormal();
			if (RotationVector.SizeSquared() > 0)
				MoveComp.SetTargetFacingDirection(RotationVector, 10.f);
			
			MoveData.ApplyTargetRotationDelta();
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();
			MoveComp.Move(MoveData);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
			MoveComp.Move(MoveData);
		}
	}

	FVector GetHorizontalAirDeltaMovement(float DeltaTime, FVector Input, float MoveSpeed)
    {    
        const FVector ForwardVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
        const FVector InputVector = Input.ConstrainToPlane(MoveComp.WorldUp);
        if(!InputVector.IsNearlyZero())
        {
            const FVector CurrentForwardVelocityDir = ForwardVelocity.GetSafeNormal();
            
            const float CorrectInputAmount = (InputVector.DotProduct(CurrentForwardVelocityDir) + 1) * 0.5f;           
        
            const FVector WorstInputVelocity = InputVector * MoveSpeed;
            const FVector BestInputVelocity = InputVector * FMath::Max(MoveSpeed, ForwardVelocity.Size());

            const FVector TargetVelocity = FMath::Lerp(WorstInputVelocity, BestInputVelocity, CorrectInputAmount);
            return FMath::VInterpConstantTo(ForwardVelocity, TargetVelocity, DeltaTime, MoveComp.DefaultMovementSettings.AirControlLerpSpeed) * DeltaTime; 
        }
        else
        {
             return ForwardVelocity * DeltaTime;
        }          
    }
}