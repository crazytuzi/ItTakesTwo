import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Peanuts.Movement.GroundTraceFunctions;

class UCharacterSprintSlowdownCapability : UCharacterMovementCapability
{
	default RespondToEvent(n"SprintSlowdown");

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	default CapabilityTags.Add(n"SprintSlowdown");

	
	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 126;

	AHazePlayerCharacter Player;
	UPROPERTY()
	USprintSettings SprintSettings;

	bool bShouldActivate = false;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);	
		SprintSettings = USprintSettings::GetSettings(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!ShouldBeGrounded())
       		return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::MovementSprint))
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(n"SprintSlowdown"))
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.Velocity.Size() <= MoveComp.MoveSpeed)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!ShouldBeGrounded())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (IsActioning(ActionNames::MovementSprint))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.Velocity.Size() <= MoveComp.MoveSpeed)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(MovementSystemTags::Sprint);
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, MovementSystemTags::Sprint);
			
			CrumbComp.LeaveMovementCrumb();	
		}

		/*if (WasActionStarted(ActionNames::MovementJump))
			Owner.SetCapabilityActionState(n"DashJump", EHazeActionState::Active);*/
	}	
	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			float MoveSpeed = MoveComp.GetRequestVelocity().Size();
			float TargetMoveSpeed = MoveComp.MoveSpeed;			
			
			float SpeedDifference = TargetMoveSpeed - MoveSpeed;
			float Deceleration = SprintSettings.Deceleration * DeltaTime;

			if (Deceleration > FMath::Abs(SpeedDifference))
				MoveSpeed = TargetMoveSpeed;
			else
				MoveSpeed -= Deceleration;

			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection).GetClampedToMaxSize(1.f);
			
			FVector Velocity = MoveInput * MoveSpeed;
			if (MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
			{
				FVector WorldUp = MoveComp.WorldUp.GetSafeNormal();
				FVector Normal = MoveComp.DownHit.Normal.GetSafeNormal();

				Velocity = Math::ConstrainVectorToSlope(Velocity, Normal, WorldUp).GetSafeNormal() * Velocity.Size();
			}

			FrameMove.ApplyVelocity(Velocity);		
			FrameMove.ApplyAndConsumeImpulses();			

			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal());
			FrameMove.ApplyTargetRotationDelta();					
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}	
}
