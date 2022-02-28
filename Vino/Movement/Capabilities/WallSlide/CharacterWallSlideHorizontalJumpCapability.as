
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureWallSlide;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Jump.CharacterJumpBufferComponent;

class UCharacterWallSlideHorizontalJumpCapability : UCharacterMovementCapability
{
	default RespondToEvent(WallslideActivationEvents::Wallsliding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(MovementSystemTags::WallSlideJump);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 145;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 31);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	// Internal
	FMovementCharacterJumpHybridData JumpData;
	AHazePlayerCharacter Player = nullptr;
	bool bPlayInAirAnim = false;
	FHazeDelayedTimer InputDelayTimer;
	FHazeDelayedTimer StickInputDelayTimer;

	bool bIsHolding = false;
	FVector JumpOffDirection = FVector::ZeroVector;

	FCharacterWallSlideHorizontalSettings Settings;

	bool bIsBlockingLedgeGrab = false;
	float TimeToBlockLedgeGrab = 0.45f;
	float BlockLedgeGrabTimer = 0.f;

	UCharacterWallSlideComponent WallDataComp;
	UCharacterJumpBufferComponent JumpBuffer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);

		WallDataComp = UCharacterWallSlideComponent::GetOrCreate(Owner);
		JumpBuffer = UCharacterJumpBufferComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WallDataComp.IsSliding())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump) && !JumpBuffer.IsJumpBuffered())
			return EHazeNetworkActivation::DontActivate;

		// TOM: Added this check, because it will trigger if your input is into the wall anyway (in cases where vertical will not trigger)
		FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (WallDataComp.ActiveWallJumpVolumes.Num() == 0 && WallDataComp.NormalPointingAwayFromWall.DotProduct(InputDirection) < 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ShouldBeGrounded())
			return RemoteLocalControlCrumbDeactivation();

		if (JumpData.GetSpeed() <= -Settings.HorizontalJumpDeactivationSpeed && !WallDataComp.IsInsideWallJumpVolume())
			return RemoteLocalControlCrumbDeactivation();

		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if(Impulse.SizeSquared() > 1)
			return RemoteLocalControlCrumbDeactivation();

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayInAirAnim = true;
		bIsHolding = true;

		BlockLedgeGrab();
		Owner.BlockCapabilities(MovementSystemTags::AirJump, this);
		JumpBuffer.ConsumeJump();

		ULocomotionFeatureWallSlide SlideFeature = ULocomotionFeatureWallSlide::Get(Player);
		if (SlideFeature != nullptr)
		{
			bPlayInAirAnim = false;

			FHazePlayLocomotionAnimationParams LocomotionAnimation;
			LocomotionAnimation.Animation = SlideFeature.WallJumpHorizontal.Sequence;
			LocomotionAnimation.BlendTime = 0.f;

			Player.PlayLocomotionAnimation(
				FHazeAnimationDelegate(),
				FHazeAnimationDelegate(this, n"OnWallJumpAnimEnded"),
				LocomotionAnimation);
		}

		JumpOffDirection = WallDataComp.NormalPointingAwayFromWall;

		StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.WallSlideJumpAwayImpulses.Vertical);

		InputDelayTimer.Start(Settings.SideInputDelayTime, Settings.SideInputDelayFadeInTime);
		StickInputDelayTimer.Start(Settings.StickInputDelayTime, Settings.StickInputFadeInTime);

		WallDataComp.SetJumpOffData(MoveComp.OwnerLocation, EWallSlideJumpOffType::Horizontal);
		WallDataComp.StopSliding(EWallSlideLeaveReason::Jumped);
		Owner.SetCapabilityActionState(WallSlideActions::HorizontalJump, EHazeActionState::Active);
	}

	UFUNCTION()
	void OnWallJumpAnimEnded()
	{
		bPlayInAirAnim = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.SetCapabilityActionState(WallSlideActions::HorizontalJump, EHazeActionState::Inactive);
		Owner.UnblockCapabilities(MovementSystemTags::AirJump, this);
		UnblockLedgeGrab();
		FVector JumpOffHeight = FVector::ZeroVector;
		Player.Mesh.ResetSubAnimationInstance();
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
        if(Notification == WallSlideActions::JumpInputStopped)
            bIsHolding = false;
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, FVector& OutInput, float DeltaTime)
	{
		// Jumping vertical movement
		const FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, true, MoveComp);

		if(HasControl())
		{
			if (GetActiveDuration() > 0.f)
			{				
				float MoveSpeed = MoveComp.HorizontalAirSpeed;
				FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
				FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				FVector VelocityDirection = HorizontalVelocity.GetSafeNormal();

				float DegreeDif = Math::DotToDegrees(VelocityDirection.DotProduct(Input));
				if (DegreeDif > 3.f && !WallDataComp.IsInsideWallJumpVolume())
				{
					float MaxTurnSpeed = (180.f * (1.f - InputDelayTimer.TimerAlpha)) * DeltaTime;
					DegreeDif = FMath::Min(MaxTurnSpeed, DegreeDif);
					FQuat RotQuat = FQuat(VelocityDirection.CrossProduct(Input), FMath::DegreesToRadians(DegreeDif));
					HorizontalVelocity = RotQuat.RotateVector(HorizontalVelocity);
				}

				if (HorizontalVelocity.Size() > 30.f)
					OutInput = HorizontalVelocity.GetSafeNormal();

				const FVector HorizontalDelta = HorizontalVelocity * DeltaTime;
				FrameMoveData.ApplyDelta(HorizontalDelta);
			}
			else
			{
				// First frame we just use the jump off force in the wall direction.
				FVector HorizontalJumpForce = JumpOffDirection * MoveComp.JumpSettings.WallSlideJumpAwayImpulses.Horizontal;
				FrameMoveData.ApplyVelocity(HorizontalJumpForce);
			}
			
			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyVelocity(VerticalVelocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
			FrameMoveData.ApplyVelocity(VerticalVelocity);
			OutInput = ConsumedParams.Velocity;	
		}

		FrameMoveData.OverrideStepUpHeight(20.f);
		FrameMoveData.OverrideStepDownHeight(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && bIsHolding)
		{
			if (!IsActioning(ActionNames::MovementDash) && !IsActioning(ActionNames::MovementJump))
			{
				TriggerNotification(WallSlideActions::JumpInputStopped);
			}
		}

		FVector InputVector = FVector::ZeroVector;
		FHazeFrameMovement FrameMoveData = MoveComp.MakeFrameMovement(n"WallJump");

		if (ActiveDuration > 0.f && WasActionStarted(ActionNames::MovementJump))
			JumpBuffer.RegisterJump();

		BlockLedgeGrabTimer -= DeltaTime;
		if (BlockLedgeGrabTimer <= 0)
		{
			UnblockLedgeGrab();
		}

		MakeFrameMovementData(FrameMoveData, InputVector, DeltaTime);
		if (bPlayInAirAnim)
		{
			FrameMoveData.ApplyTargetRotationDelta();
			MoveCharacter(FrameMoveData, FeatureName::AirMovement);
		}
		else
		{
			FHazeLocomotionTransform RootMotionDelta;
			Player.RequestRootMotion(DeltaTime, RootMotionDelta);
			FQuat CurrentRotation = RootMotionDelta.WorldRotation;

			float TurnSpeed = 0.f;
			if (!InputVector.IsNearlyZero() && StickInputDelayTimer.DelayTimeLeft <= 0.f)
			{
				FQuat InputRotation = InputVector.ToOrientationQuat();
				FQuat InputRotationDelta = InputRotation * MoveComp.OwnerRotation.Inverse();
				CurrentRotation = InputRotationDelta * CurrentRotation;
				TurnSpeed = MoveComp.ActiveSettings.AirRotationSpeed;
			}

			MoveComp.SetTargetFacingRotation(CurrentRotation.Rotator(), TurnSpeed);
			FrameMoveData.ApplyTargetRotationDelta();
			MoveComp.Move(FrameMoveData);
		}

		CrumbComp.LeaveMovementCrumb();
		InputDelayTimer.Update(DeltaTime);
		StickInputDelayTimer.Update(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";

		return Str;
	} 

	void BlockLedgeGrab()
	{
		if (!Owner.HasControl())
			return;

		if (!ensure(!bIsBlockingLedgeGrab))
			return;

		BlockLedgeGrabTimer = TimeToBlockLedgeGrab;
		bIsBlockingLedgeGrab = true;
		Owner.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
	}

	void UnblockLedgeGrab()
	{
		if (!bIsBlockingLedgeGrab)
			return;

		if (!ensure(Owner.HasControl()))
			return;

		bIsBlockingLedgeGrab = false;
		Owner.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
	}
};
