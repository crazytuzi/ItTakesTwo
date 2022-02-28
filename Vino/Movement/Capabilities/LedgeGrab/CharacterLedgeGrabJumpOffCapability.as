
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabGlobalFunctions;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

class UCharacterLedgeGrabJumpOffCapability : UCharacterMovementCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 155;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 43);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	FMovementCharacterJumpHybridData JumpData;
	ULedgeGrabComponent LedgeGrabComp;

	FCharacterLedgeGrabSettings Settings;

	bool bIsHolding = false;
	bool bStartedDescending = false;

	FName ActiveJumpOffButton = NAME_None;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (!(LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Hang) || LedgeGrabComp.IsCurrentState(ELedgeGrabStates::Entering)))
			return EHazeNetworkActivation::DontActivate;
		
		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (WantsToJumpAwayFromLedge(LedgeGrabComp.GrabData.NormalPointingAwayFromWall, GetAttributeVector(AttributeVectorNames::MovementDirection)))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (JumpData.GetSpeed() <= -MoveComp.MaxFallSpeed)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		FVector Impulse = FVector::ZeroVector;
        MoveComp.GetAccumulatedImpulse(Impulse);
        if(Impulse.SizeSquared() > FMath::Square(500.f))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveJumpOffButton = ActionNames::MovementDash;
		if (WasActionStarted(ActionNames::MovementJump))
			ActiveJumpOffButton = ActionNames::MovementJump;

		bStartedDescending = false;
		bIsHolding = true;

		CharacterOwner.SetCapabilityActionState(n"ResetAirDash", EHazeActionState::Active);

		StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.LedgeGrabJumpAwayImpulses.Vertical);

		FVector ForceDirection = CalculateJumpOffVector();

		FVector HorizontalJumpForce = ForceDirection * MoveComp.JumpSettings.LedgeGrabJumpAwayImpulses.Horizontal; 
		MoveComp.AddImpulse(HorizontalJumpForce);

		MoveComp.SetTargetFacingDirection(ForceDirection);
		MoveComp.StopIgnoringComponent(LedgeGrabComp.LedgeGrabData.LedgeGrabbed);
		LedgeGrabComp.SetState(ELedgeGrabStates::JumpOff);	
		LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::JumpOff);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		LedgeGrabComp.SetStateIfCurrentState(ELedgeGrabStates::JumpOff, ELedgeGrabStates::None);
	}

	FVector CalculateJumpOffVector() const
	{
		FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(MoveComp.WorldUp);

		if (InputDirection.Size() < 0.3f)
			InputDirection = LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall;

		float WallVsInputDot = InputDirection.DotProduct(LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall);
		if (WallVsInputDot < Settings.MaxExtraHangSideInput)
			return FVector::ZeroVector;

		float WallDegress = Math::DotToDegrees(WallVsInputDot);
		if (WallDegress > 90.f - Settings.MaxDegreeSideInputVector)
		{
			FVector WallRightVector = LedgeGrabComp.LedgeGrabData.NormalPointingAwayFromWall.CrossProduct(MoveComp.WorldUp);

			float InputVsRightVector = WallRightVector.DotProduct(InputDirection);
			float Rotation = Settings.MaxDegreeSideInputVector;
			if (InputVsRightVector < 0.f)
				Rotation = 180.f - Settings.MaxDegreeSideInputVector;

			FQuat ClampedRotation = FQuat(MoveComp.WorldUp, FMath::DegreesToRadians(Rotation));

			InputDirection = ClampedRotation.RotateVector(WallRightVector);
		}

		return InputDirection;
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == LedgeGrabSyncNames::StartedDescending)
			bStartedDescending = true;
	}

	void BuildFrameMovement(FHazeFrameMovement& JumpOffMove, float DeltaTime)
	{
		if (HasControl())
		{
			// Vertical
			if (bIsHolding && !IsActioning(ActiveJumpOffButton))
				bIsHolding = false;

			FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, bIsHolding, MoveComp);
			JumpOffMove.ApplyVelocity(VerticalVelocity);

			// Horizontal
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;

			FVector HorizontalDelta = GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveSpeed);
			JumpOffMove.ApplyDelta(HorizontalDelta);

			// ---
			JumpOffMove.ApplyAndConsumeImpulses();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
	 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
	 		JumpOffMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		JumpOffMove.OverrideStepUpHeight(0.f);
		JumpOffMove.OverrideStepDownHeight(0.f);
		JumpOffMove.ApplyTargetRotationDelta();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// On the remote we let the activation of the climb let us now that the hang/entering capability should deactivate.
		if (!HasControl() && !MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement JumpOffMove = MoveComp.MakeFrameMovement(LedgeGrabTags::JumpAway);
		BuildFrameMovement(JumpOffMove, DeltaTime);

		// When our vertical speed turns we send that as a notification so the other side gets to the peak. (this will be one frame behind the peak).
		const int VertSign = FMath::Sign(JumpData.GetSpeed());
		if (!bStartedDescending && VertSign <= 0.f)
		{
			TriggerNotification(LedgeGrabSyncNames::StartedDescending);
		}
		
		MoveCharacter(JumpOffMove, FeatureName::LedgeGrab, FeatureName::LedgeJumpOff);
		CrumbComp.LeaveMovementCrumb();
	}

	bool WantsToJumpAwayFromLedge(FVector WallNormal, FVector InputDirection) const
	{
		if (InputDirection.Size() < Settings.JumpOffMinStickInput)
			return false;

		if (InputDirection.DotProduct(WallNormal) < Settings.MaxExtraHangSideInput)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		if(HasControl())
		{

		}
		else
		{
			Str += "MoveType: ";
			// const FHazeActorReplication TargetParams = GetReplicationParams(SyncMovementComp);						
			// if(TargetParams.ReachedType == EHazeReachedType::NotReched)
			// {
			// 	Str += "<Green>Moving" + "</>\n";
			// }
			// else if(TargetParams.ReachedType == EHazeReachedType::Reached)
			// {
			// 	Str += "<Blue>Reached" + "</>\n";
			// }
			// else if(TargetParams.ReachedType == EHazeReachedType::ReachedButCanContinue)
			// {
			// 	Str += "<Yellow>Continue" + "</>\n";
			// }
			// else
			// {
			// 	Str += "<Red>???" + "</>\n";
			// }
		}

		return Str;
	} 
};
