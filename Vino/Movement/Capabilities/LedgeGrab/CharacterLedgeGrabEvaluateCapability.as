
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabNames;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;

class UCharacterLedgeGrabEvaluateCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);
	default RespondToEvent(LedgeGrabActivationEvents::Cooldown);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LedgeGrab);
	default CapabilityTags.Add(LedgeGrabTags::Evaluate);

	default CapabilityDebugCategory = CapabilityTags::Movement;	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 39;

	UPROPERTY()
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	ULedgeGrabComponent LedgeGrabComp;

	UCharacterWallSlideComponent WallSlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		LedgeGrabComp = ULedgeGrabComponent::GetOrCreate(Owner);
		WallSlideComp = UCharacterWallSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		// Tick inactivity timer.
		LedgeGrabComp.TickInactiveTimer(Owner.ActorDeltaSeconds);
		if (LedgeGrabComp.AllowedToActivate())
			ConsumeAction(LedgeGrabActivationEvents::Cooldown);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (WallSlideComp.HasSlidingTarget())
			return EHazeNetworkActivation::DontActivate;

		if (!LedgeGrabComp.AllowedToActivate())	
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
	
		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::None))
			return EHazeNetworkActivation::ActivateLocal;

		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::JumpOff))
			return EHazeNetworkActivation::ActivateLocal;

		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::JumpUp))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WallSlideComp.HasSlidingTarget())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!LedgeGrabComp.AllowedToActivate())	
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::None))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::JumpOff))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (LedgeGrabComp.IsCurrentState(ELedgeGrabStates::JumpUp))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		LedgeGrabComp.TargetLedgeData = FLedgeGrabPhysicalData();	
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FLedgeGrabPhysicalData LedgeData;
		if (ShouldEnterLedgeGrab(LedgeData))
			LedgeGrabComp.SetTargetLedge(LedgeData);
	}

	bool ShouldEnterLedgeGrab(FLedgeGrabPhysicalData& OutData) const
	{
		if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) > LedgeGrabComp.Settings.WallCheckMaxAllowedUpwardsSpeed)
			return false;		

		if (CheckIfCharacterWantsToEnterHang(OutData))
			return true;

		return false;
	}

	bool CheckIfCharacterWantsToEnterHang(FLedgeGrabPhysicalData& OutData) const
	{
		FLedgeGrabCheckData WorkData;
		WorkData.MoveComp = MoveComp;
		WorkData.OwningPlayer = Cast<AHazePlayerCharacter>(WorkData.MoveComp.Owner);

		OutData = FLedgeGrabPhysicalData();

		if (!ensure(WorkData.OwningPlayer != nullptr))
			return false;

		WorkData.Settings = LedgeGrabComp.Settings.GetScaledLedgeGrabSettings(WorkData.MoveComp.ActorScale);
		FHazeTraceParams WallTrace;
		WallTrace.InitWithMovementComponent(MoveComp);
		WallTrace.UnmarkToTraceWithOriginOffset();
		WallTrace.SetToSphere(WorkData.Settings.WallTraceSphereRadius);

		WallTrace.From = WorkData.MoveComp.OwnerLocation + WorkData.MoveComp.OwnerRotation.ForwardVector * WorkData.Settings.WallCheckStartForwardOffset + WorkData.MoveComp.WorldUp * WorkData.Settings.WallCheckPositionHeight;

		const float AmountForwardToTrace = WorkData.Settings.WallCheckForwardDistance + WorkData.Settings.WallTraceSphereRadius + (WorkData.MoveComp.ActorShapeExtents.X);
		WallTrace.To = WallTrace.From + WorkData.MoveComp.OwnerRotation.ForwardVector * AmountForwardToTrace;

		// Check if there is a wall infront of us.
		FHazeHitResult WallHit;
		if (!WallTrace.Trace(WallHit)) 
			return false;

		if (!WallHit.Component.HasTag(ComponentTags::LedgeGrabbable))
			return false;
		
		if (WallHit.ImpactNormal.DotProduct(MoveComp.WorldUp) > 0.05f)
			return false;

		AHazeActor HitActor = Cast<AHazeActor>(WallHit.Actor);
		if (HitActor != nullptr)
		{
			UHazeMovementComponent OtherActorMoveComp = UHazeMovementComponent::Get(HitActor);
			if (OtherActorMoveComp != nullptr && !OtherActorMoveComp.bAllowOtherActorsToMoveWithTheActor)
				return false;
		}

		FHazeHitResult TopHit;
		FHazeHitResult ForwardHit = WallHit;
		if (!GetTopOfCollider(WorkData, WallHit.ImpactNormal, WallHit.ImpactPoint, TopHit, ForwardHit))
			return false;

		if (!ForwardHit.Component.HasTag(ComponentTags::LedgeGrabbable))
			return false;

		FTransform LeftHandLocation;
		FTransform RightHandLocation;
		if (!GetHandLocations(WorkData, TopHit.ImpactPoint, TopHit.ImpactNormal, WallHit.ImpactNormal, LeftHandLocation, RightHandLocation))
			return false;

		FVector WallNormal = ((-LeftHandLocation.Rotation.ForwardVector) + (-RightHandLocation.Rotation.ForwardVector)) /2.f;
		FVector LedgePosition = (LeftHandLocation.Location + RightHandLocation.Location) / 2.f;

		const FVector ConstrainedWallNormal = WallNormal.ConstrainToPlane(WorkData.MoveComp.WorldUp).SafeNormal;
		FVector WantToHangPosition = LedgePosition;
		
		WantToHangPosition += Math::ConstructRotatorFromUpAndForwardVector(-ConstrainedWallNormal, WorkData.MoveComp.WorldUp).RotateVector(WorkData.Settings.HangOffset);
		WallTrace.SetToCapsule(MoveComp.ActorShapeExtents.X, MoveComp.ActorShapeExtents.Z);
		WallTrace.MarkToTraceWithOriginOffset();
		WallTrace.OverlapLocation = WantToHangPosition;

		if (WallTrace.Overlap(TArray<FOverlapResult>()))
			return false;

		OutData.NormalPointingAwayFromWall = ConstrainedWallNormal;
		OutData.LedgeGrabbed = WallHit.Component;

		FQuat HangLocationRot = Math::MakeQuatFromXZ(-ConstrainedWallNormal, MoveComp.WorldUp);
		OutData.ActorHangLocation = FTransform(HangLocationRot, WantToHangPosition);
		
		FVector ScaleVector = Owner.ActorScale3D;
		FTransform HangTransform = FTransform(HangLocationRot, WantToHangPosition, ScaleVector);
		OutData.LeftHandRelative = LeftHandLocation.GetRelativeTransform(HangTransform);
		OutData.RightHandRelative = RightHandLocation.GetRelativeTransform(HangTransform);

		FHazeTraceParams MoveCompTraceSettings;
		MoveCompTraceSettings.InitWithMovementComponent(MoveComp);
		OutData.ContactMat = Audio::GetPhysMaterialFromHit(OutData.ForwardHit, MoveCompTraceSettings);

		return true;
	}

	bool GetTopOfCollider(FLedgeGrabCheckData& WorkData, FVector WallNormal, FVector ImpactPoint, FHazeHitResult& OutHit, FHazeHitResult& OutForwardHit) const
	{
		FVector TraceDelta = WallNormal * WorkData.Settings.FindLedgePositionTraceDepth;

		const FVector SegmentHeightDelta = WorkData.MoveComp.WorldUp * WorkData.Settings.FindLedgeGapHeightTraceSegments;
		FVector TraceStartLocation = ImpactPoint - TraceDelta.GetSafeNormal() * WorkData.Settings.WallTraceSphereRadius;
		const FVector ExtendedTraceDelta = TraceDelta + TraceDelta.GetSafeNormal() * WorkData.Settings.WallTraceSphereRadius;

		FHazeTraceParams ForwardTrace;
		ForwardTrace.InitWithMovementComponent(WorkData.MoveComp);
		ForwardTrace.UnmarkToTraceWithOriginOffset();
		ForwardTrace.SetToLineTrace();
		ForwardTrace.From = TraceStartLocation;
		ForwardTrace.To = ForwardTrace.From + ExtendedTraceDelta;

		int IterationCount = (WorkData.Settings.FindLedgePositionTraceMaxHeight / WorkData.Settings.FindLedgeGapHeightTraceSegments) + 1;
		while (IterationCount-- > 0)
		{
			FHazeHitResult ForwardHit;
			if (!ForwardTrace.Trace(ForwardHit))
			{
				FHazeTraceParams TopTrace = ForwardTrace;
				TopTrace.From = TopTrace.From;
				TopTrace.To = TopTrace.From - (SegmentHeightDelta * 2.f);

				FHazeHitResult TopHit;
				if (TopTrace.Trace(TopHit))
				{
					if (TopHit.bStartPenetrating)
						continue;

					float TopItTilt = Math::DotToDegrees(TopHit.Normal.DotProduct(WorkData.MoveComp.WorldUp));
					if (TopItTilt > WorkData.Settings.MaxTopTilt)
						return false;

					// We discard anything angled away from the player since that has a high likelyhood of cutting in to the player and not give good hand locations.
					float LedgeAngleDirection = WallNormal.ConstrainToPlane(WorkData.MoveComp.WorldUp).SafeNormal.DotProduct(TopHit.Normal);
					if (LedgeAngleDirection < -0.01f)
						return false;

					OutHit = TopHit;
					return true;
				}
			}
			else
			{
				OutForwardHit = ForwardHit;
			}

			ForwardTrace.From += SegmentHeightDelta;
			ForwardTrace.To = ForwardTrace.From + ExtendedTraceDelta;
		}

		return false;
	}

	bool GetHandLocations(FLedgeGrabCheckData WorkData, FVector TopLocation, FVector TopNormal, FVector WallNormal, FTransform& OutLeftHandPos, FTransform& OutRightHandPos) const
	{
		FVector HandDelta = TopNormal.CrossProduct(WallNormal).SafeNormal * WorkData.Settings.HandOffset;

		FHazeHitResult LeftTopHit;
		if (!TraceForHand(WorkData, TopLocation + HandDelta, TopNormal, WallNormal, LeftTopHit, OutLeftHandPos))
			return false;

		FHazeHitResult RightTopHit;
		if (!TraceForHand(WorkData, TopLocation - HandDelta, TopNormal, WallNormal, RightTopHit, OutRightHandPos))
			return false;

		UPrimitiveComponent LeftComp = LeftTopHit.Component;
		UPrimitiveComponent RightComp = RightTopHit.Component;
		if (LeftComp != RightComp)
		{
			if (LeftComp.Mobility == EComponentMobility::Movable)
				return false;
			
			if (RightComp.Mobility == EComponentMobility::Movable)
				return false;
		}

		float WallNormalDifferance = Math::DotToDegrees(OutLeftHandPos.Rotation.ForwardVector.DotProduct(OutRightHandPos.Rotation.ForwardVector));
		if (WallNormalDifferance > WorkData.Settings.MaxAllowedWallNormalDifference)
			return false;

		return true;
	}

	bool TraceForHand(FLedgeGrabCheckData WorkData, FVector HandTopPos, FVector TopNormal, FVector WallNormal, FHazeHitResult& OutHit, FTransform& OutTransform) const
	{
		FHazeTraceParams HandTrace;
		HandTrace.InitWithMovementComponent(WorkData.MoveComp);
		HandTrace.UnmarkToTraceWithOriginOffset();
		HandTrace.SetToLineTrace();
		HandTrace.DebugDrawTime = IsDebugActive() ? 0.f : -1.f;

		HandTrace.To = HandTopPos - (TopNormal * WorkData.Settings.HandLowering);
		HandTrace.From = HandTrace.To + (WallNormal * WorkData.Settings.HandForwardTrace);

		FHazeHitResult ForwardHit;
		if (!HandTrace.Trace(ForwardHit))
			return false;
		
		if (ForwardHit.bStartPenetrating)
			return false;
		
		HandTrace.To = ForwardHit.ImpactPoint - ForwardHit.ImpactNormal * WorkData.Settings.FindLedgePositionTraceDepth;
		HandTrace.From = HandTrace.To + TopNormal * WorkData.Settings.FindHandPositionHeightTrace;
		FHazeHitResult TopHit;
		if (!HandTrace.Trace(TopHit))
			return false;

		if (TopHit.bStartPenetrating)
			return false;

		if (!TopHit.Component.HasTag(ComponentTags::LedgeGrabbable))
			return false;

		OutHit = TopHit;
		FQuat HandRotation = Math::MakeQuatFromXZ(-ForwardHit.ImpactNormal, TopHit.ImpactNormal);
		OutTransform = FTransform(HandRotation, TopHit.ImpactPoint);

		return true;
	}

}
