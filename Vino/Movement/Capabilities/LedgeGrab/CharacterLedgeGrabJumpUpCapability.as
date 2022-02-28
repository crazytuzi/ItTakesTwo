
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabGlobalFunctions;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

class UCharacterLedgeGrabJumpUpCapability : UCharacterMovementCapability
{
	default RespondToEvent(LedgeGrabActivationEvents::Grabbing);

	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::JumpUp);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 155;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 45);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	FMovementCharacterJumpHybridData JumpData;

	ULedgeGrabComponent LedgeGrabComp;

	bool bStartedDescending = false;
	bool bIsHolding = false;

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

		if (!CanJumpUp())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
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
		bIsHolding = true;
		CharacterOwner.SetCapabilityActionState(n"ResetAirDash", EHazeActionState::Active);
		MoveComp.StopIgnoringComponent(LedgeGrabComp.LedgeGrabData.LedgeGrabbed);
		LedgeGrabComp.SetState(ELedgeGrabStates::JumpUp);
		LedgeGrabComp.LetGoOfLedge(ELedgeReleaseType::JumpUp);

		StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.LedgeNodeJumpUpImpulse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		LedgeGrabComp.SetStateIfCurrentState(ELedgeGrabStates::JumpUp, ELedgeGrabStates::None);
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == LedgeGrabSyncNames::StartedDescending)
			bStartedDescending = true;
	}

	void BuildFrameMovement(FHazeFrameMovement& JumpUpMove, float DeltaTime)
	{
		if (HasControl())
		{
			// Vertical
			if (bIsHolding && !IsActioning(ActionNames::MovementJump))
				bIsHolding = false;

			FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, bIsHolding, MoveComp);
			JumpUpMove.ApplyVelocity(VerticalVelocity);

			// Horizontal
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;

			FVector HorizontalDelta = GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveSpeed);
			JumpUpMove.ApplyDelta(HorizontalDelta);

			// ---
			JumpUpMove.ApplyAndConsumeImpulses();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
	 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
	 		JumpUpMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		JumpUpMove.OverrideStepUpHeight(0.f);
		JumpUpMove.OverrideStepDownHeight(0.f);
		JumpUpMove.ApplyTargetRotationDelta();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// On the remote we let the activation of the jump let us now that the hang/entering capability should deactivate.
		if (!HasControl() && !MoveComp.CanCalculateMovement())
			return;

		// Jumping vertical movement
		FHazeFrameMovement JumpUpMove = MoveComp.MakeFrameMovement(LedgeGrabTags::JumpUp);
		BuildFrameMovement(JumpUpMove, DeltaTime);

		// When our vertical speed turns we send that as a notification so the other side gets to the peak. (this will be one frame behind the peak).
		const int VertSign = FMath::Sign(JumpData.GetSpeed());
		if (!bStartedDescending && VertSign <= 0.f)
			TriggerNotification(LedgeGrabSyncNames::StartedDescending);

		MoveCharacter(JumpUpMove, FeatureName::LedgeGrab, FeatureName::LedgeJumpUp);
		CrumbComp.LeaveMovementCrumb();
	}

	bool CanJumpUp() const
	{
		FCharacterLedgeGrabSettings ScaledGrabSettings = LedgeGrabComp.Settings.GetScaledLedgeGrabSettings(MoveComp.ActorScale);
		FVector HangOffset = Math::ConstructRotatorFromUpAndForwardVector(MoveComp.OwnerRotation.Vector(), MoveComp.WorldUp).RotateVector(ScaledGrabSettings.HangOffset);

		FVector CapsuleExtens = MoveComp.ActorShapeExtents;
		FVector CurrentPositionWithLedgeHeight = MoveComp.OwnerLocation - FVector(0.f, 0.f, HangOffset.Z) + MoveComp.WorldUp * CapsuleExtens.Z;

		FHazeTraceParams Query;
		Query.InitWithMovementComponent(MoveComp);
		Query.UnmarkToTraceWithOriginOffset();
		Query.TraceShape = FCollisionShape::MakeBox(CapsuleExtens);
		Query.OverlapLocation = CurrentPositionWithLedgeHeight;

		TArray<FOverlapResult> OverlapResults;
		if (Query.Overlap(OverlapResults))
		{
			if (IsDebugActive())
				System::DrawDebugBox(CurrentPositionWithLedgeHeight, CapsuleExtens, FLinearColor::Red, MoveComp.OwnerRotation.Rotator(),  1.f);
			
			return false;
		}

		if (IsDebugActive())
			System::DrawDebugBox(CurrentPositionWithLedgeHeight, CapsuleExtens, FLinearColor::Green, MoveComp.OwnerRotation.Rotator(),  1.f);
		
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
