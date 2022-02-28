import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingStatics;

import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Helpers.MovementJumpHybridData;

class UCharacterSlidingJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Sliding");
	default CapabilityTags.Add(n"SlidingJump");
	default CapabilityTags.Add(MovementSystemTags::Jump);

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 144;

	AHazePlayerCharacter Player;
	UCharacterSlidingComponent SlidingComp;

	UPROPERTY()
	float JumpImpulse = 2000.f;
	float GravityStrength = 4000.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		

    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsGrounded())
       		return EHazeNetworkActivation::DontActivate;

		if (!SlidingComp.bIsSliding)
       		return EHazeNetworkActivation::DontActivate;

		if (WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
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

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.UpHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		if (MoveComp.ForwardHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		// If any impulses are applied, cancel the jump
		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if (!Impulse.IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (ActivationParams.IsStale())
			return;

		MoveComp.SetVelocity(MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp));
		MoveComp.AddImpulse(MoveComp.WorldUp * JumpImpulse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SlidingJump");
		CalculateFrameMove(FrameMove, DeltaTime);

		FName AnimTag;
		if (MoveComp.GetVelocity().DotProduct(MoveComp.WorldUp) >= 0.f)
			AnimTag = FeatureName::Jump;
		else
			AnimTag = FeatureName::AirMovement;

		MoveCharacter(FrameMove, AnimTag);

		CrumbComp.LeaveMovementCrumb();		
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			// FrameMove.ApplyVelocity(FVector::ZeroVector);
			// FrameMove.ApplyActorHorizontalVelocity();
			// FrameMove.ApplyActorVerticalVelocity();
			FrameMove.ApplyAndConsumeImpulses();

			// Update velocity speed
			Velocity += GetGravityAcceleration(DeltaTime);

			// Update velocity rotation
			// Velocity = GetSlopeRotatedVelocity(Velocity, DeltaTime);
			// Velocity = GetInputRotatedVelocity(Velocity, DeltaTime);

			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal());
			
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideStepUpHeight(0.f);
			FrameMove.ApplyVelocity(Velocity);
		
			FrameMove.ApplyTargetRotationDelta();	
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);	
		}	
	}

	FVector GetGravityAcceleration(float DeltaTime)
	{
		return -MoveComp.WorldUp * GravityStrength * DeltaTime;
	}
}
