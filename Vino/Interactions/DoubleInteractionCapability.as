import Vino.Interactions.DoubleInteractionActor;

class UDoubleInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"EventAnimation");
	
	ADoubleInteractionActor ActiveInteraction;
	AHazePlayerCharacter Player;
	bool bEnterCompleted = false;
	bool bCancelPromptShown = false;
	bool bAwaitingPredictiveEnter = false;

	FDoubleInteractionAnimations Animations;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ADoubleInteractionActor Interaction = Cast<ADoubleInteractionActor>(GetAttributeObject(n"DoubleInteraction"));
		if (Interaction == nullptr)
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		ADoubleInteractionActor Interaction = Cast<ADoubleInteractionActor>(GetAttributeObject(n"DoubleInteraction"));
		if (Interaction == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::Cancel) && bEnterCompleted)
			ActiveInteraction.CancelPressed_ControlSide(Player);

		if (ActiveInteraction.bShowCancelPrompt)
		{
			if (ActiveInteraction.CanPlayerCancelInteraction(Player) && bEnterCompleted)
			{
				if (!bCancelPromptShown)
				{
					if (ActiveInteraction.bOverrideCancelText)
						Player.ShowCancelPromptWithText(this, ActiveInteraction.OverrideCancelText);
					else
						Player.ShowCancelPrompt(this);
					bCancelPromptShown = true;
				}
			}
			else
			{
				if (bCancelPromptShown)
				{
					Player.RemoveCancelPromptByInstigator(this);
					bCancelPromptShown = false;
				}
			}
		}

		if (bAwaitingPredictiveEnter)
		{
			if (!Player.IsPlayingAnimAsSlotAnimation(Animations.Enter))
			{
				OnEnterAnimationFinished();
				bAwaitingPredictiveEnter = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveInteraction = Cast<ADoubleInteractionActor>(GetAttributeObject(n"DoubleInteraction"));
		bEnterCompleted = false;
		bAwaitingPredictiveEnter = false;

		Animations = ActiveInteraction.GetAnimations(Player);

		if (IsActioning(n"PredictiveEnterActive"))
		{
			ActiveInteraction.OnEnterAnimationStarted(Player);
			bAwaitingPredictiveEnter = true;
		}
		else if (IsActioning(n"PredictiveMHActive"))
		{
			ActiveInteraction.OnEnterAnimationStarted(Player);
			ActiveInteraction.OnMHAnimationStarted(Player);
			ActiveInteraction.SetReadyForComplete(Player, true);
			bEnterCompleted = true;
		}
		else
		{
			Owner.PlaySlotAnimation(
				Animation = Animations.Enter,
				OnBlendingOut = FHazeAnimationDelegate(this, n"OnEnterAnimationFinished"),
				BlendTime = Animations.BlendTime
			);
			ActiveInteraction.OnEnterAnimationStarted(Player);
		}

		ConsumeAction(n"PredictiveEnterActive");
		ConsumeAction(n"PredictiveMHActive");
	}

	UFUNCTION()
	void OnEnterAnimationFinished()
	{
		Owner.PlaySlotAnimation(
			Animation = Animations.MH,
			bLoop = true
		);

		ActiveInteraction.OnMHAnimationStarted(Player);
		ActiveInteraction.SetReadyForComplete(Player, true);
		bEnterCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		if (ActiveInteraction != nullptr)
		{
			if (Animations.Enter != nullptr)
				Player.StopAnimationByAsset(Animations.Enter);
			if (Animations.MH != nullptr)
				Player.StopAnimationByAsset(Animations.MH);

			ActiveInteraction.SetReadyForComplete(Player, false);
			ActiveInteraction.OnAnimationsStopped(Player);
		}
		else
		{
			Player.StopAllSlotAnimations();
		}

		if (bCancelPromptShown)
		{
			Player.RemoveCancelPromptByInstigator(this);
			bCancelPromptShown = false;
		}
	}
};