import Vino.Interactions.DoubleInteractionActor;

class UDoubleInteractionPredictiveAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UHazeTriggerComponent ActiveTrigger;
	ADoubleInteractionActor ActiveDoubleInteraction;
	FDoubleInteractionAnimations Animations;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UHazeTriggerComponent Trigger = Cast<UHazeTriggerComponent>(GetAttributeObject(n"ValidatingTrigger"));
		if (Trigger == nullptr)
			return EHazeNetworkActivation::DontActivate;

		ADoubleInteractionActor DoubleInteract = Cast<ADoubleInteractionActor>(Trigger.Owner);
		if (DoubleInteract == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (Trigger != DoubleInteract.LeftInteraction && Trigger != DoubleInteract.RightInteraction)
			return EHazeNetworkActivation::DontActivate;
		if (!DoubleInteract.bUsePredictiveAnimation)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// This is deactivated when the waiting sheet is removed by the interaction
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveTrigger = Cast<UHazeTriggerComponent>(GetAttributeObject(n"ValidatingTrigger"));
		ActiveDoubleInteraction = Cast<ADoubleInteractionActor>(ActiveTrigger.Owner);
		Animations = ActiveDoubleInteraction.GetAnimations(Player, ActiveTrigger);

		if (Animations.Enter != nullptr)
		{
			Owner.SetCapabilityActionState(n"PredictiveEnterActive", EHazeActionState::Active);
			Player.PlaySlotAnimation(
				OnBlendingOut = FHazeAnimationDelegate(this, n"OnPredictiveEnterFinished"),
				Animation = Animations.Enter,
				BlendTime = Animations.BlendTime
			);
		}
		else if (Animations.MH != nullptr)
		{
			Owner.SetCapabilityActionState(n"PredictiveMHActive", EHazeActionState::Active);
			Player.PlaySlotAnimation(
				OnBlendingOut = FHazeAnimationDelegate(this, n"OnPredictiveMHCanceled"),
				Animation = Animations.MH,
				BlendTime = Animations.BlendTime,
				bLoop = true
			);
		}
	}

	UFUNCTION()
	void OnPredictiveEnterFinished()
	{
		if (IsActioning(n"PredictiveEnterActive"))
		{
			ConsumeAction(n"PredictiveEnterActive");

			Owner.SetCapabilityActionState(n"PredictiveMHActive", EHazeActionState::Active);
			Player.PlaySlotAnimation(
				OnBlendingOut = FHazeAnimationDelegate(this, n"OnPredictiveMHCanceled"),
				Animation = Animations.MH,
				BlendTime = Animations.BlendTime,
				bLoop = true
			);
		}
	}

	UFUNCTION()
	void OnPredictiveMHCanceled()
	{
		ConsumeAction(n"PredictiveMHActive");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (ActiveDoubleInteraction == nullptr
			|| !IsActioning(n"TriggerValidationAccepted")
			|| Player.bIsControlledByCutscene
			|| IsBlocked())
		{
			Player.StopAnimationByAsset(Animations.Enter);
			Player.StopAnimationByAsset(Animations.MH);

			ConsumeAction(n"PredictiveEnterActive");
			ConsumeAction(n"PredictiveMHActive");
		}
	}
};