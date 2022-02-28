import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureTurnAround;
import Vino.Movement.Helpers.StickFlickTracker;

class UCharacterFloorTurnAroundCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
	default CapabilityTags.Add(MovementSystemTags::TurnAround);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 149;

	bool bInputWantsToActivate = false;

	bool bHasTurnAroundFeature;

	TArray<FVector> StickHistory;

	int ActiveHistorySlot = 0;
	float InactiveTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!bHasTurnAroundFeature)
			return EHazeNetworkActivation::DontActivate;

		if (!bInputWantsToActivate)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(!ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ActiveDuration >= 0.125f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		ULocomotionFeatureTurnAround TurnAroundFeature = ULocomotionFeatureTurnAround::Get(CharacterOwner);
		bHasTurnAroundFeature = TurnAroundFeature != nullptr;

		StickHistory.SetNum(10);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		InactiveTimer = 0.f;
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		MoveComp.SetTargetFacingDirection(Input.GetSafeNormal(), 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		// We allow the timer since the only time it won't tick is when you are in the air.
		// I don't think issues related to it will be noticable.
		if (!IsActive())
			InactiveTimer += Owner.ActorDeltaSeconds;

		bInputWantsToActivate = false;

		// We only want to activate when we are in basic movement.
		if (CharacterOwner.Mesh.LocomotionFeatureCount > 1)
			return;

		if (uint(CharacterOwner.Mesh.FeatureCacheFrameNumber) >= GFrameNumber)
		{
			ULocomotionFeatureTurnAround TurnAroundFeature = ULocomotionFeatureTurnAround::Get(CharacterOwner);
			bHasTurnAroundFeature = TurnAroundFeature != nullptr;
		}

		if (bHasTurnAroundFeature)
		{
			FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			StickHistory[ActiveHistorySlot++] = MovementDirection;

			if (ActiveHistorySlot >= StickHistory.Num())
				ActiveHistorySlot = 0;

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if ((Math::DotToDegrees(Owner.ActorForwardVector.DotProduct(Input)) > 150.f)
				&& StickHistoryCheck())
			{
				if (InactiveTimer < 0.6f)
					InactiveTimer = 0.f;
				else
					bInputWantsToActivate = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement TurnAroundMovement = MoveComp.MakeFrameMovement(n"TurnAround");
	
		if(HasControl())
		{
			TurnAroundMovement.ApplyTargetRotationDelta();
			TurnAroundMovement.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbParams);
			TurnAroundMovement.ApplyConsumedCrumbData(CrumbParams);
		}

		SendMovementAnimationRequest(TurnAroundMovement, FeatureName::TurnAround, NAME_None);
		MoveComp.Move(TurnAroundMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	bool StickHistoryCheck() const
	{
		const FVector CurrentMoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (CurrentMoveDirection.IsNearlyZero())
			return false;

		FQuat Rot = Math::ConstructRotatorFromUpAndForwardVector(CurrentMoveDirection, MoveComp.WorldUp).Quaternion();

		const FVector CurrentInputForward = Rot.ForwardVector;
		const FVector CurrentInputRightVector = Rot.RightVector;

		bool bStickWasInOtherDirection = false;

		for (const FVector& PastStick : StickHistory)
		{
			if (PastStick.IsNearlyZero())
				continue;

			if (FMath::Abs(CurrentInputRightVector.DotProduct(PastStick)) > 0.5f)
				return false;

			if (CurrentInputForward.DotProduct(PastStick) < 0.f)
				bStickWasInOtherDirection = true;
		}

		return bStickWasInOtherDirection;
	}
}
