import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Animation.Features.LocomotionFeatureLanding;
import Vino.Movement.MovementSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingStatics;
import Vino.Movement.Capabilities.Crouch.CharacterCrouchComponent;

class UCharacterCrouchCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
	default CapabilityTags.Add(MovementSystemTags::Crouch);
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 111;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterCrouchComponent CrouchComp;

	float CrouchMoveSpeed = 400.f;

	//Static value of how much we keep of the force
	const float ForceGroundFrictionValue = 0.14f;

	float CurrentForwardSpeed = 0.f;
	
	USlidingSettings SlidingSettings;
	float OriginalCapsuleHeight;

	bool bJumpBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrouchComp = UCharacterCrouchComponent::GetOrCreate(Owner);		
		SlidingSettings = USlidingSettings::GetSettings(Owner);
		OriginalCapsuleHeight = CharacterOwner.CapsuleComponent.CapsuleHalfHeight;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::MovementCrouch) && !CrouchComp.IsCrouchingForced())
			return EHazeNetworkActivation::DontActivate;

		if(ShouldBeGrounded())
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(!ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (CheckPlayerCapsuleHit(Player, OriginalCapsuleHeight))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!IsActioning(ActionNames::MovementCrouch) && CrouchComp.ForceCrouchScore <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		Owner.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		Owner.BlockCapabilities(n"BlockedWhileCrouching", this);
		BlockJump();

		CrouchComp.ResetForceCrouch();

		UMovementSettings::SetMoveSpeed(Owner, CrouchMoveSpeed, this);
		CharacterOwner.CapsuleComponent.HazeSetCapsuleHalfHeight(SlidingSettings.CrouchHeight * 0.5f);
		CurrentForwardSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		Owner.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);
		Owner.UnblockCapabilities(n"BlockedWhileCrouching", this);
		UnblockJump();

		Owner.ClearSettingsByInstigator(this);
		CharacterOwner.CapsuleComponent.HazeSetCapsuleHalfHeight(OriginalCapsuleHeight);

		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, false);
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		UnblockJump();
	}

	void PlayLandingAnimation()
	{
		ULocomotionFeatureLanding LandingFeature = ULocomotionFeatureLanding::Get(CharacterOwner);
		if(LandingFeature != nullptr && LandingFeature.Landing.Sequence != nullptr)
		{
			FHazePlayAdditiveAnimationParams AddativeParams;
			AddativeParams.Animation = LandingFeature.Landing.Sequence;
			AddativeParams.PlayRate = LandingFeature.Landing.PlayRate;
			AddativeParams.BoneFilter = LandingFeature.BoneFilter;
			AddativeParams.BlendTime = LandingFeature.BlendTime;
			
			CharacterOwner.PlayAdditiveAnimation(FHazeAnimationDelegate(), AddativeParams);
		}
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
	{
		if(HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.MoveSpeed;

			float TargetSpeed = MoveSpeed * Input.GetClampedToSize(0.4f, 1.f).Size();
			
			float AccelerationSpeed = MoveSpeed / 0.35f;
			CurrentForwardSpeed += AccelerationSpeed * DeltaTime;
			
			if (CurrentForwardSpeed > TargetSpeed)
				CurrentForwardSpeed = TargetSpeed;

			FVector InputMoveDelta = Input.GetSafeNormal() * CurrentForwardSpeed * DeltaTime;
			//FVector InputMoveDelta = Input.GetClampedToSize(0.4f, 1.f) * MoveSpeed * DeltaTime;
			FVector MoveDelta = InputMoveDelta;

			if (MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
			{
				FVector WorldUp = MoveComp.WorldUp.GetSafeNormal();
				FVector Normal = MoveComp.DownHit.Normal.GetSafeNormal();				

				MoveDelta = Math::ConstrainVectorToSlope(Input, Normal, WorldUp).GetSafeNormal() * InputMoveDelta.Size();
			}
			
			//We only apply forces on the controlside and let the remote be affected through by it indirectly from syncing the position.
			FVector ForceVelocity = MoveComp.ConsumeAccumulatedImpulse();
			ForceVelocity = ScaleUpForce(ForceVelocity, DeltaTime);
		
			//We need to constrain the force to the horizontal plain since we allow small vertical forces through.
			ForceVelocity = Math::ConstrainVectorToPlane(ForceVelocity, MoveComp.WorldUp);
			MoveDelta += (ForceVelocity * DeltaTime);

			/// TEST IF YOU ARE WALKING OFF OF A PLATFORM
				// Test if the player is grounded at the target location
			/*FVector TraceStartLocation = Owner.ActorLocation + MoveDelta;
			FVector TraceEndLocation = TraceStartLocation - FVector(0.f, 0.f, MoveComp.ActiveSettings.StepUpAmount);
			float TraceCapsuleRadius = CharacterOwner.CapsuleComponent.CapsuleRadius;
			float TraceCapsuleHalfHeight = CharacterOwner.CapsuleComponent.CapsuleHalfHeight; 
			TArray<AActor> ActorsToIgnore;
			FHitResult Hit;
			System::LineTraceSingleByProfile(TraceStartLocation, TraceEndLocation, n"PlayerCharacter", false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, Hit, false);
			
			if (!Hit.bBlockingHit)
			{
				FVector LedgeGrabTraceStartLocation = TraceStartLocation + (MoveDelta.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * TraceCapsuleRadius * 4) - (MoveComp.WorldUp * TraceCapsuleHalfHeight);
				System::DrawDebugPoint(LedgeGrabTraceStartLocation, 20.f);
				FVector TraceDirection = -MoveDelta.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
				FHitResult CapHit;
				System::CapsuleTraceSingleByProfile(LedgeGrabTraceStartLocation, LedgeGrabTraceStartLocation + (TraceDirection * TraceCapsuleRadius * 4), TraceCapsuleRadius, TraceCapsuleHalfHeight, n"PlayerCharacter", false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, CapHit, true);

				if (CapHit.bBlockingHit)
				{
					CharacterOwner.SetActorLocationAndRotation(CapHit.Location - (TraceDirection * 2), Math::MakeRotFromX(TraceDirection));
				}

				FCapabilityTagDuration BlockDuration;
				BlockDuration.CapabilityTag = n"Input";
				BlockDuration.Duration = 0.2f;
				BlockCapabilityTagTemporarily(Owner, BlockDuration);
				



				MoveDelta = FVector::ZeroVector;
			}*/
					
					//MoveComp.Step
				// Check if is in stepdown range
				// If it is not, check where they can stand
					// trace  backwards?
					
			if (CrouchComp.IsGroundedForce())
				FrameMoveData.OverrideGroundedState(EHazeGroundedState::Grounded);
			
			FrameMoveData.ApplyDelta(MoveDelta);
			FrameMoveData.ApplyTargetRotationDelta();
			FrameMoveData.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
		}


	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"CrouchMove");

		MakeFrameMovementData(FinalMovement, DeltaTime);

		if (MoveComp.BecameGrounded())
		{
			SendMovementAnimationRequest(FinalMovement, FeatureName::Landing, NAME_None);
		}
		else
		{
			SendMovementAnimationRequest(FinalMovement, MovementSystemTags::Crouch, NAME_None);
		}
	
		MoveComp.Move(FinalMovement);
		CrumbComp.LeaveMovementCrumb();

		// Print Debug
		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, IsDebugActive());
		}

		FHazeTraceParams Trace;
		Trace.InitWithMovementComponent(MoveComp);
		Trace.ShapeRotation = Player.CapsuleComponent.WorldRotation.Quaternion();
		Trace.SetToCapsule(Player.CapsuleComponent.CapsuleRadius, OriginalCapsuleHeight);
		Trace.OverrideOriginOffset(FVector(0.f, 0.f, OriginalCapsuleHeight));

		Trace.From = Owner.ActorLocation;
		Trace.To = Owner.ActorLocation + MoveComp.WorldUp;

		FHazeHitResult Hit;
		if (Trace.Trace(Hit))
		{
			BlockJump();
		}
		else
			UnblockJump();
	}

	FVector ScaleUpForce(FVector InputForce, float DeltaTime) const
	{
		//We allow forces set this frame to affect this frames delta movement, we scale the force up since we only apply it for one frame.
		//Note: Since floor movement doesn't use the characters velocity the forces will only have an effect for one frame.
		FVector OutputForce = InputForce;

		OutputForce = InputForce / DeltaTime;
			
		//We apply friction to the force so the same force in the air will have greater effect.
		OutputForce = OutputForce * ForceGroundFrictionValue;

		return OutputForce;
	}


	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		return Str;
	} 

	void BlockJump()
	{
		if (bJumpBlocked)
			return;

		Owner.BlockCapabilities(n"Jump", this);
		bJumpBlocked = true;
	}

	void UnblockJump()
	{
		if (!bJumpBlocked)
			return;

		Owner.UnblockCapabilities(n"Jump", this);
		bJumpBlocked = false;
	}

}
