import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

class UClockworkBirdGroundedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdGrounded");

	default CapabilityDebugCategory = n"ClockworkBirdGrounded";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 102;

	AClockworkBird Bird;

	bool bPlayerAttached = true;

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

		if (Bird.bIsFlying || Bird.bIsLanding)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Bird.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.StopTimeline();
		Bird.BirdRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{						
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdGrounded");
		if (HasControl())
		{
			FVector MovementVec = Bird.PlayerInput;
			if (MoveComp.DownHit.bBlockingHit)
			{
				FVector WorldUp = MoveComp.WorldUp;
				FVector Normal = MoveComp.DownHit.Normal;	

				MovementVec = Math::ConstrainVectorToSlope(MovementVec, Normal, WorldUp).GetSafeNormal() * MovementVec.Size();
			}

			MovementVec *= MoveComp.MoveSpeed * DeltaTime;
			
			if (MoveComp.IsGrounded())
				MoveData.ApplyDelta(MovementVec);

			MovementVec.Normalize();
			
			if (MovementVec.Size() > 0)
			{
				MoveComp.SetTargetFacingDirection(MovementVec, 10.f);
				//System::DrawDebugArrow(Owner.GetActorLocation(), FVector(Owner.GetActorLocation() + FVector(MovementVec * 500.f)));
			}
			
			MoveData.ApplyTargetRotationDelta();
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
}
