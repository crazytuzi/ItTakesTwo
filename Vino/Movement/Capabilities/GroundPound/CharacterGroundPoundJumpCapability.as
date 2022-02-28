import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Jump.AirJumpsComponent;

class UCharacterGroundPoundJumpCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Landed);

	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Start);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(n"GroundPoundJumpOnly");

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 5;

	UCharacterAirJumpsComponent AirJumpsComp;
	UCharacterGroundPoundComponent GroundPoundComp;
	AHazePlayerCharacter PlayerOwner = nullptr;

	float EnterDuration = 1.f;
	float FallTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsAllowLandedAction(0.f))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundPoundComp.ChangeToState(EGroundPoundState::Jumping);
		AirJumpsComp.ConsumeJump();

		// Set ABP state
		GroundPoundComp.AnimationData.bIsJumping = true;
		GroundPoundComp.AnimationData.JumpType = EGroundPoundJumpType::High;

		FVector InheritedVelocity = MoveComp.GetInheritedVelocity();
		MoveComp.OnJumpTrigger(InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp), InheritedVelocity.ConstrainToDirection(MoveComp.WorldUp).Size());

		// Set jump velocity
		MoveComp.SetVelocity(MoveComp.WorldUp * MoveComp.JumpSettings.GroundPoundJumpImpulse + InheritedVelocity);

		PlayerOwner.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		PlayerOwner.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Make move data
		FHazeFrameMovement JumpMove = MoveComp.MakeFrameMovement(n"GroundPoundJump");

		// Set airborne state
		JumpMove.OverrideStepUpHeight(0.f);
		JumpMove.OverrideStepDownHeight(0.f);
		JumpMove.OverrideGroundedState(EHazeGroundedState::Airborne);

		if(HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection).GetSafeNormal();
			JumpMove.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveComp.GetHorizontalAirSpeed()));
			JumpMove.ApplyActorVerticalVelocity();

			FVector GravityAcceleration = MoveComp.Gravity * MoveComp.JumpSettings.JumpGravityScale * DeltaTime;
			JumpMove.ApplyDelta(GravityAcceleration * DeltaTime);

			FVector JumpVelocity = MoveComp.Velocity + GravityAcceleration;

			// Get input from velocity and apply rotation if needed
			FVector InputVelocity = ((FVector::OneVector - MoveComp.WorldUp) * JumpVelocity.GetSafeNormal()).GetSafeNormal();
			if(!InputVelocity.IsNearlyZero())
				MoveComp.SetTargetFacingDirection(InputVelocity, ActiveMovementSettings.AirRotationSpeed);

			JumpMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			JumpMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(JumpMove, FeatureName::GroundPound);
		CrumbComp.LeaveMovementCrumb();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.IsMovingUpwards())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		GroundPoundComp.ResetState();
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		if (ActiveDuration > 0.f)
			PlayerOwner.Mesh.ResetSubAnimationInstance();
	}
}
