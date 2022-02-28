import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.ComboAnimations.ComboAnimationData;

/*
	Base class for use with systems that use combo animations.
	The following methods are important to override:
	 - ShouldStartCombo
	 - ShouldProceedInCombo
	 - ComboHit
*/
UCLASS(Abstract)
class UComboAnimationCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 10;

	UPROPERTY()
	UComboAnimationData ComboData;

	int ActiveCombo = -1;
	float ElementTimer = 0.f;
	FVector AppliedMovement;
	FRotator ElementStartRotation;

	bool bComboFinished = false;
	bool bComboDropped = false;

	bool bWantsToProceed = false;
	bool bProceededThisFrame = false;

	TArray<bool> RemoteDecisionQueue;

	bool ShouldStartCombo() const
	{
		return false;
	}

	bool ShouldProceedInCombo() const
	{
		return false;
	}

	void ComboHit(int ComboIndex)
	{
	}

	float GetPreviousLockedDuration() const
	{
		const FComboElement& Elem = ComboData.ComboAnimations[ActiveCombo];
		return Elem.InitialLockedDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ComboData == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (ShouldStartCombo())
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bComboFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bComboFinished = false;
		bComboDropped = false;

		StartComboElement(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	void StartComboElement(int ComboIndex)
	{
		const FComboElement& Elem = ComboData.ComboAnimations[ComboIndex];

		devEnsure(Elem.HitTiming <= Elem.InitialLockedDuration,
			"Combo animation HitTiming should never be after InitialLockedDuration, or you can miss hits.");

		devEnsure(Elem.HitTiming <= Elem.InitialLockedDuration,
			"Combo animation MovementDuration should never be after InitialLockedDuration, or you can miss movement.");

		// Play the slot animation set up for this combo element if there is one
		if (Elem.AnimationMode == EComboAnimationMode::SlotAnimation)
		{
			Owner.PlaySlotAnimation(Animation = Elem.SlotAnimation);
		}

		// Restart element data
		ElementTimer = 0.f;
		AppliedMovement = FVector(0.f);
		ActiveCombo = ComboIndex;
		ElementStartRotation = Owner.ActorRotation;

		bWantsToProceed = false;
		bProceededThisFrame = true;
	}

	UFUNCTION(NetFunction)
	void NetSendDecision(bool bProceed)
	{
		if (!HasControl())
		{
			RemoteDecisionQueue.Add(bProceed);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FComboElement& Elem = ComboData.ComboAnimations[ActiveCombo];

		float PrevElementTimer = ElementTimer;
		ElementTimer += DeltaTime;

		// Perform hits callback if we reached the correct part of the animation
		if (PrevElementTimer < Elem.HitTiming && ElementTimer >= Elem.HitTiming)
		{
			ComboHit(ActiveCombo);
		}

		if (HasControl())
		{
			// Determine whether we're in a state where we can proceed to the next element of the combo
			bool bCanProceedInCombo = true;
			bool bIsInComboDropped = false;

			// Don't allow proceed in the lock duration
			if (ElementTimer <= Elem.InitialLockedDuration)
			{
				bCanProceedInCombo = false;
			}
			// Don't allow proceed in the drop duration
			if (ElementTimer >= Elem.Duration - Elem.FinalDropDuration)
			{
				bIsInComboDropped = true;

				// We can still proceed for one tick if we just hit the boundary
				if (PrevElementTimer >= Elem.Duration - Elem.FinalDropDuration)
					bCanProceedInCombo = false;
			}
			// Don't allow proceed if we run out of combos and can't loopn
			if (ActiveCombo == ComboData.ComboAnimations.Num() - 1)
			{
				if (!ComboData.bCanLoopBackToStart)
					bCanProceedInCombo = false;
			}
			// If we're no longer grounded, we cannot proceed, we must drop
			if (!MoveComp.IsGrounded())
				bCanProceedInCombo = false;

			// We can mark for proceed at any point
			if (!bWantsToProceed && !bProceededThisFrame && ShouldProceedInCombo())
			{
				bWantsToProceed = true;
			}

			// Proceed to the next combo animation when we can
			if (bCanProceedInCombo && bWantsToProceed)
			{
				int NewCombo = (ActiveCombo + 1) % ComboData.ComboAnimations.Num();
				StartComboElement(NewCombo);
				NetSendDecision(true);
			}
			else if (bIsInComboDropped && !bComboDropped)
			{
				// Determine that the combo is now permanently dropped
				bComboDropped = true;
				NetSendDecision(false);
			}

			if (bComboDropped)
			{
				if (ElementTimer >= Elem.Duration)
				{
					// Combo completely finished, shut off the capability
					bComboFinished = true;
				}
			}
		}
		else
		{
			bool bHaveDecision = RemoteDecisionQueue.Num() != 0;
			if (bHaveDecision)
			{
				bool bDecision = RemoteDecisionQueue[0];
				if (bDecision && ElementTimer >= Elem.InitialLockedDuration)
				{
					RemoteDecisionQueue.RemoveAt(0);
					int NewCombo = (ActiveCombo + 1) % ComboData.ComboAnimations.Num();
					StartComboElement(NewCombo);
				}

				if (!bDecision && ElementTimer >= Elem.Duration)
				{
					RemoteDecisionQueue.RemoveAt(0);
					bComboFinished = true;
				}
			}
		}

		// Do actual character movement stuff
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ComboAnimation");

			if (HasControl())
			{
				if (ComboData.ControlMode != EComboControlMode::Locked)
					FrameMove.ApplyTargetRotationDelta();
				FrameMove.ApplyGravityAcceleration();
				FrameMove.ApplyActorVerticalVelocity();

				// Where in the initial movement do we want to be right now?
				FVector TargetMovement = Elem.InitialMovement;
				if (Elem.MovementDuration > 0.f)
					TargetMovement *= FMath::Clamp(ElementTimer / Elem.MovementDuration, 0.f, 1.f);

				FVector RotatedMovement = (TargetMovement - AppliedMovement);
				if (ComboData.ControlMode != EComboControlMode::Free)
					RotatedMovement = ElementStartRotation.RotateVector(RotatedMovement);
				else
					RotatedMovement = Owner.ActorTransform.TransformVectorNoScale(RotatedMovement);
				AppliedMovement = TargetMovement;

				FrameMove.ApplyDelta(RotatedMovement);
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				FrameMove.ApplyConsumedCrumbData(ConsumedParams);
			}

			// Request the right feature if we have one specified
			FName AnimRequest = n"Movement";
			FName AnimSubTag = NAME_None;

			if (Elem.AnimationMode == EComboAnimationMode::Feature)
			{
				AnimRequest = Elem.FeatureTag;
				AnimSubTag = Elem.FeatureSubTag;
			}

			MoveCharacter(FrameMove, AnimRequest, AnimSubTag);
			CrumbComp.LeaveMovementCrumb();
		}

		bProceededThisFrame = false;
	}
};