
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureWallSlide;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;

class UCharacterWallSlideVerticalJumpCapability : UCharacterMovementCapability
{
	default RespondToEvent(WallslideActivationEvents::Wallsliding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(MovementSystemTags::WallSlideJump);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 145;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 30);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	float InputDelayTime = .025f;

	UPROPERTY()
	float InputDelayFadeInTime = 0.025f;

	// Internal
	FMovementCharacterJumpHybridData JumpData;
	AHazePlayerCharacter Player = nullptr;
	bool bPlayInAirAnim = false;
	FHazeDelayedTimer InputDelayTimer;

	bool bIsHolding = false;
	bool bShouldActivateWallJumpOff = false;

	bool bIsBlockingLedgeGrab = false;
	float TimeToBlockLedgeGrab = 0.45f;
	float BlockLedgeGrabTimer = 0.f;
	
	bool bIsBlockingAirJump = false;
	float TimeToBlockAirJump = 0.225f;

	UCharacterWallSlideComponent WallDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WallDataComp = UCharacterWallSlideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WallDataComp.IsSliding())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (WallDataComp.NormalPointingAwayFromWall.DotProduct(InputDirection) >= 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (WallDataComp.ActiveWallJumpVolumes.Num() > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (JumpData.GetSpeed() <= -MoveComp.MaxFallSpeed)
			return EHazeNetworkDeactivation::DeactivateLocal;

		FVector Impulse = FVector::ZeroVector;
		MoveComp.GetAccumulatedImpulse(Impulse);
		if(Impulse.SizeSquared() > 1)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WallDataComp.SetJumpOffData(MoveComp.OwnerLocation, EWallSlideJumpOffType::Vertical);

		if (ActivationParams.IsStale())
		{
			WallDataComp.StopSliding(EWallSlideLeaveReason::JumpedUp);
			return;
		}

		bPlayInAirAnim = true;
		bIsHolding = true;

		BlockLedgeGrab();
		BlockAirJump();

		ULocomotionFeatureWallSlide SlideFeature = ULocomotionFeatureWallSlide::Get(Player);
		if (SlideFeature != nullptr)
		{
			bPlayInAirAnim = false;

			FHazePlayLocomotionAnimationParams LocomotionAnimation;
			LocomotionAnimation.Animation = SlideFeature.WallJump.Sequence;
			LocomotionAnimation.BlendTime = 0.f;

			Player.PlayLocomotionAnimation(
				FHazeAnimationDelegate(),
				FHazeAnimationDelegate(this, n"OnWallJumpAnimEnded"),
				LocomotionAnimation);
		}

		FVector ForceDirection = -Owner.ActorRotation.Vector();
		FVector HorizontalJumpForce = ForceDirection * MoveComp.JumpSettings.WallSlideJumpUpImpulses.Horizontal;

		StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.WallSlideJumpUpImpulses.Vertical);

		MoveComp.AddImpulse(HorizontalJumpForce);
		InputDelayTimer.Start(InputDelayTime, InputDelayFadeInTime);

		WallDataComp.StopSliding(EWallSlideLeaveReason::JumpedUp);
	}

	UFUNCTION()
	void OnWallJumpAnimEnded()
	{
		bPlayInAirAnim = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FVector JumpOffHeight = FVector::ZeroVector;

		UnblockLedgeGrab();
		UnblockAirJump();
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
			float MoveSpeed = MoveComp.HorizontalAirSpeed;
			OutInput = GetAttributeVector(AttributeVectorNames::MovementDirection);			
			OutInput = FMath::Lerp(FVector::ZeroVector, OutInput, 1 - InputDelayTimer.TimerAlpha);	
	
			const FVector HorizontalDelta = GetHorizontalAirDeltaMovement(DeltaTime, OutInput, MoveSpeed);
			
			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyDelta(HorizontalDelta);
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

		FrameMoveData.ApplyTargetRotationDelta();
		FrameMoveData.OverrideStepUpHeight(20.f);
		FrameMoveData.OverrideStepDownHeight(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && bIsHolding)
		{
			if (!IsActioning(ActionNames::MovementJump))
				TriggerNotification(WallSlideActions::JumpInputStopped);
		}

		FVector InputVector = FVector::ZeroVector;
		FHazeFrameMovement FrameMoveData = MoveComp.MakeFrameMovement(n"WallJump");

		BlockLedgeGrabTimer -= DeltaTime;
		if (BlockLedgeGrabTimer <= 0)
		{
			UnblockLedgeGrab();
		}

		if (ActiveDuration >= TimeToBlockAirJump)
			UnblockAirJump();

		MakeFrameMovementData(FrameMoveData, InputVector, DeltaTime);
		if (bPlayInAirAnim)
		{
			MoveCharacter(FrameMoveData, FeatureName::AirMovement);
		}
		else
		{
			FHazeLocomotionTransform RootMotionDelta;
			Player.RequestRootMotion(DeltaTime, RootMotionDelta);
			FQuat CurrentRotation = RootMotionDelta.WorldRotation;

			float TurnSpeed = 0.f;
			if (!InputVector.IsNearlyZero() && InputDelayTimer.DelayTimeLeft <= 0.f)
			{
				FQuat InputRotation = InputVector.ToOrientationQuat();
				FQuat InputRotationDelta = InputRotation * MoveComp.OwnerRotation.Inverse();
				CurrentRotation = InputRotationDelta * CurrentRotation;			
				TurnSpeed = 9.f;
			}

			// MoveComp.SetTargetFacingRotation(CurrentRotation.Rotator(), TurnSpeed);
			FrameMoveData.ApplyTargetRotationDelta();
			MoveComp.Move(FrameMoveData);
		}

		CrumbComp.LeaveMovementCrumb();
		InputDelayTimer.Update(DeltaTime);

		if(IsDebugActive())
		{
			FVector PlayerLocation = Player.ActorLocation;
			FVector PreviousLocation = PlayerLocation - FrameMoveData.MovementDelta;

			float SpeedAlpha = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp).Size() / MoveComp.MaxFallSpeed;

			TArray<FLinearColor> Colors;
			Colors.Add(FLinearColor::Red);
			Colors.Add(FLinearColor::Yellow);
			Colors.Add(FLinearColor::Green);
			FLinearColor Color = LerpColors(Colors, SpeedAlpha);

			System::DrawDebugLine(PreviousLocation, PlayerLocation, Color, 5.f, 3.f);
		}
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

	void BlockAirJump()
	{
		if (!Owner.HasControl())
			return;

		if (bIsBlockingAirJump)
			return;

		bIsBlockingAirJump = true;
		Owner.BlockCapabilities(MovementSystemTags::AirJump, this);
	}

	void UnblockAirJump()
	{
		if (!Owner.HasControl())
			return;
		
		if (!bIsBlockingAirJump)
			return;
		
		bIsBlockingAirJump = false;
		Owner.UnblockCapabilities(MovementSystemTags::AirJump, this);
	}
};
