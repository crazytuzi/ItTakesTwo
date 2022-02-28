import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Triggers.VOBarkTriggerComponent;

event void FOnDoubleInteractionCompleted();
event void FOnLeftInteractionReady(AHazePlayerCharacter Player);
event void FOnRightInteractionReady(AHazePlayerCharacter Player);
event void FOnPlayerCanceledDoubleInteraction(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction);
event void FOnDoubleInteractBarkTriggered(AHazePlayerCharacter Barker);

struct FDoubleInteractionAnimations
{
	UPROPERTY()
	UAnimSequence Enter;
	UPROPERTY()
	UAnimSequence MH;
	UPROPERTY()
	UAnimSequence Exit;
	UPROPERTY(AdvancedDisplay)
	float BlendTime = 0.2f;
};

enum EDoubleInteractionExclusiveMode
{
	NotExclusive,
	LeftSideCodyRightSideMay,
	LeftSideMayRightSideCody,
};

/**
 * A standard double interaction where both players
 * can enter and cancel independently, and the interaction
 * proceeds when both players are entered at the same time.
 *
 * Players are animated using a three-shot.
 */
class ADoubleInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftInteraction;
	default LeftInteraction.RelativeLocation = FVector(0.f, -100.f, 0.f);
	default LeftInteraction.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent RightInteraction;
	default RightInteraction.RelativeLocation = FVector(0.f, 100.f, 0.f);
	default RightInteraction.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(Category = "Double Interaction")
	bool bShowCancelPrompt = true;

	UPROPERTY(Category = "Double Interaction", Meta = (InlineEditConditionToggle))
	bool bOverrideCancelText = false;

	UPROPERTY(Category = "Double Interaction", Meta = (EditCondition = "bOverrideCancelText"))
	FText OverrideCancelText;

	// Whether to play the exit animation on the players after the double interaction completes
	UPROPERTY(Category = "Double Interaction")
	bool bPlayExitAnimationOnCompleted = false;

	// If set, the interaction will not be completed, even after both players are locked into it.
	UPROPERTY(Category = "Double Interaction")
	bool bPreventInteractionFromCompleting = false;

	// Whether to make the interactions exclusive for specific players
	UPROPERTY(Category = "Double Interaction")
	EDoubleInteractionExclusiveMode ExclusiveMode = EDoubleInteractionExclusiveMode::NotExclusive;

	// Sheet to add to the player while they are in the double interaction
	UPROPERTY(Category = "Double Interaction", AdvancedDisplay)
	UHazeCapabilitySheet DoubleInteractionSheet = Asset("/Game/Blueprints/Interactions/DoubleInteractionSheet.DoubleInteractionSheet");

	// Whether to use predictive animations in network
	UPROPERTY(Category = "Double Interaction", AdvancedDisplay)
	bool bUsePredictiveAnimation = true;

	// Main event that gets broadcast when the double interact is complete
	UPROPERTY()
	FOnDoubleInteractionCompleted OnDoubleInteractionCompleted;
	UPROPERTY()
	FOnLeftInteractionReady OnLeftInteractionReady;
	UPROPERTY()
	FOnRightInteractionReady OnRightInteractionReady;
	UPROPERTY()
	FOnPlayerCanceledDoubleInteraction OnPlayerCanceledDoubleInteraction;
	UPROPERTY()
	FOnDoubleInteractionCompleted OnBothPlayersLockedIntoInteraction;
	UPROPERTY()
	FOnDoubleInteractBarkTriggered OnVOBarkTriggered;

	UPROPERTY(Category = "Left Interaction Animations")
	FDoubleInteractionAnimations CodyLeftAnimations;

	UPROPERTY(Category = "Left Interaction Animations")
	FDoubleInteractionAnimations MayLeftAnimations;

	UPROPERTY(Category = "Right Interaction Animations")
	FDoubleInteractionAnimations CodyRightAnimations;

	UPROPERTY(Category = "Right Interaction Animations")
	FDoubleInteractionAnimations MayRightAnimations;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerCancelAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoubleInteractStartAudioEvent;

	/* If set, the actor's tick will be turned off when the interaction is not waiting for anything */
	UPROPERTY(Category = "Tick")
	bool bTurnOffTickWhenNotWaiting = true;

	// If this component has an asset set, we will trigger barks from that asset when 
	// one player has been interacting with this double interact fro the given delay time
	// Per audio team request, these will by default trigger continuously.
	UPROPERTY(DefaultComponent, ShowOnActor, Category = "VOBark")
	UVOBarkTriggerComponent VOBarkTriggerComponent;
	default VOBarkTriggerComponent.Delay = 1.f;
	default VOBarkTriggerComponent.RetriggerDelays.Add(1.f);
	default VOBarkTriggerComponent.bRepeatForever = true;

	// If true, bark triggering will be independently triggered on each side in network.
	// Since barks are triggered continuosly and are just reminders default is true.
	UPROPERTY(Category = "VOBark")
	bool bVOBarkTriggerLocally = true;

	private TPerPlayer<bool> ReadyForCancel;
	private TPerPlayer<bool> ReadyForComplete;
	private TPerPlayer<UInteractionComponent> ActiveInteractions;
	private bool bWaitingForComplete = false; 
	private AHazePlayerCharacter FirstInteractor = nullptr;
	private AHazePlayerCharacter TriggeredLastInteractor = nullptr;
	private TPerPlayer<bool> BarkReady;

	default PrimaryActorTick.bStartWithTickEnabled = false;


	UFUNCTION(BlueprintEvent)
	bool CanInteractionBeCompleted()
	{
		return true;
	}

	UFUNCTION(BlueprintEvent)
	void OnStartedInteracting(AHazePlayerCharacter Player, UInteractionComponent Interaction)
	{
		StartAnimation(Player);
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetLastInteractingPlayer()
	{
		return TriggeredLastInteractor;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto EditorBillboard = UBillboardComponent::Create(this);
		EditorBillboard.bIsEditorOnly = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftInteraction.OnActivated.AddUFunction(this, n"OnInteractionUsed");
		RightInteraction.OnActivated.AddUFunction(this, n"OnInteractionUsed");
		DoubleInteract.OnTriggered.AddUFunction(this, n"OnDoubleInteractTriggered");

		switch (ExclusiveMode)
		{
			case EDoubleInteractionExclusiveMode::LeftSideCodyRightSideMay:
				LeftInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
				RightInteraction.SetExclusiveForPlayer(EHazePlayer::May);
			break;
			case EDoubleInteractionExclusiveMode::LeftSideMayRightSideCody:
				LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
				RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
			break;
		}

		OnLeftInteractionReady.AddUFunction(this, n"VOBarkReady");
		OnRightInteractionReady.AddUFunction(this, n"VOBarkReady");
		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"VOBarkCancel");
		OnDoubleInteractionCompleted.AddUFunction(this, n"VOBarkCompleted");
		VOBarkTriggerComponent.OnVOBarkTriggered.AddUFunction(this, n"BarkTriggered");
		VOBarkTriggerComponent.bTriggerLocally = bVOBarkTriggerLocally;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckForInteractionComplete();
		if (!bWaitingForComplete && bTurnOffTickWhenNotWaiting)
			SetActorTickEnabled(false);
	}

	bool CanPlayerCancelInteraction(AHazePlayerCharacter Player)
	{
		if (bWaitingForComplete)
			return false;
		if (!ReadyForCancel[Player])
			return false;
		return DoubleInteract.CanPlayerCancel(Player);
	}

	void CancelInteraction(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			DoubleInteract.CancelInteracting(Player);

		UInteractionComponent UsedInteraction = ActiveInteractions[Player];
		ExitFromInteraction(Player, bPlayExitAnimation = true);

		if (HasControl())
		{
			if (FirstInteractor == Player)
			{
				if (ActiveInteractions[Player.OtherPlayer] != nullptr)
					NetSetFirstInteractor(Player.OtherPlayer);
				else
					NetSetFirstInteractor(nullptr);
			}
		}

		OnPlayerCanceledDoubleInteraction.Broadcast(Player, UsedInteraction, UsedInteraction == LeftInteraction);
	}

	void SetReadyForComplete(AHazePlayerCharacter Player, bool bReady)
	{
		ReadyForComplete[Player] = bReady;
		CheckForInteractionComplete();
	}

	UFUNCTION()
	void Enable(FName Reason)
	{
		LeftInteraction.Enable(Reason);
		RightInteraction.Enable(Reason);
	}

	UFUNCTION()
	void EnableAfterFullSyncPoint(FName Reason)
	{
		LeftInteraction.EnableAfterFullSyncPoint(Reason);
		RightInteraction.EnableAfterFullSyncPoint(Reason);
	}

	UFUNCTION()
	void Disable(FName Reason)
	{
		LeftInteraction.Disable(Reason);
		RightInteraction.Disable(Reason);
	}

	const FDoubleInteractionAnimations& GetAnimations(AHazePlayerCharacter Player)
	{
		if (ActiveInteractions[Player] == LeftInteraction)
		{
			if (Player.IsCody())
				return CodyLeftAnimations;
			else
				return MayLeftAnimations;
		}
		else
		{
			if (Player.IsCody())
				return CodyRightAnimations;
			else
				return MayRightAnimations;
		}
	}

	const FDoubleInteractionAnimations& GetAnimations(AHazePlayerCharacter Player, UHazeTriggerComponent Trigger)
	{
		if (Trigger == LeftInteraction)
		{
			if (Player.IsCody())
				return CodyLeftAnimations;
			else
				return MayLeftAnimations;
		}
		else
		{
			if (Player.IsCody())
				return CodyRightAnimations;
			else
				return MayRightAnimations;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionUsed(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		ReadyForComplete[Player] = false;
		ReadyForCancel[Player] = false;
		ActiveInteractions[Player] = UsedInteraction;
		UsedInteraction.Disable(n"InUse");

		//PrintToScreenScaled("interaction used", 2.f, FLinearColor :: LucBlue, 2.f);
		Player.PlayerHazeAkComp.HazePostEvent(OnePlayerInteractAudioEvent);

		if (HasControl())
		{
			if (FirstInteractor == nullptr)
				NetSetFirstInteractor(Player);
		}

		OnStartedInteracting(Player, UsedInteraction);
		DoubleInteract.StartInteracting(Player);
	}

	UFUNCTION(NetFunction)
	void NetSetFirstInteractor(AHazePlayerCharacter Player)
	{
		FirstInteractor = Player;
	}

	void StartAnimation(AHazePlayerCharacter Player)
	{
		auto UsedInteraction = ActiveInteractions[Player];

		if (!Network::IsNetworked())
			ReadyForCancel[Player] = true;
		else if (!Player.HasControl())
			NetSetRemoteReadyForCancel(Player);

		Player.AddCapabilitySheet(DoubleInteractionSheet, Priority = EHazeCapabilitySheetPriority::Interaction, Instigator = this);
		Player.TriggerMovementTransition(Instigator = this);
		Player.AttachRootComponentTo(UsedInteraction, AttachLocationType = EAttachLocation::SnapToTarget);

		Player.SetCapabilityAttributeObject(n"DoubleInteraction", this);
		OnLeftOrRightInteractionReady(UsedInteraction, Player);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetRemoteReadyForCancel(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			ReadyForCancel[Player] = true;
	}


	UFUNCTION()
	void OnLeftOrRightInteractionReady(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		if(UsedInteraction == LeftInteraction)
		{
			OnLeftInteractionReady.Broadcast(Player);
		}
		else
		{
			OnRightInteractionReady.Broadcast(Player);
		}
	}

	private void ExitFromInteraction(AHazePlayerCharacter Player, bool bPlayExitAnimation)
	{
		Player.DetachRootComponentFromParent();
		Player.RemoveAllCapabilitySheetsByInstigator(Instigator = this);
		//PrintToScreenScaled("exit from interaction", 2.f, FLinearColor :: LucBlue, 2.f);
		Player.PlayerHazeAkComp.HazePostEvent(OnePlayerCancelAudioEvent);

		if (bPlayExitAnimation)
		{
			Player.PlayEventAnimation(Animation = GetAnimations(Player).Exit, BlendTime = GetAnimations(Player).BlendTime);
			OnExitAnimationStarted(Player);
		}

		ActiveInteractions[Player].Enable(n"InUse");
		ActiveInteractions[Player] = nullptr;

		Player.SetCapabilityAttributeObject(n"DoubleInteraction", nullptr);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDoubleInteractTriggered()
	{
		devEnsure(FirstInteractor != nullptr, "DoubleInteraction FirstInteractor was null");
		TriggeredLastInteractor = FirstInteractor.OtherPlayer;

		bWaitingForComplete = true;
		OnBothPlayersLockedIntoInteraction.Broadcast();
		CheckForInteractionComplete();
		SetActorTickEnabled(true);

		//PrintToScreenScaled("double interact triggered", 2.f, FLinearColor :: LucBlue, 2.f);
		UHazeAkComponent::HazePostEventFireForget(DoubleInteractStartAudioEvent, this.GetActorTransform());
	}

	private void CheckForInteractionComplete()
	{
		if (!bWaitingForComplete)
			return;
		if (!CanInteractionBeCompleted())
			return;
		if (bPreventInteractionFromCompleting)
			return;

		for (auto Player : Game::Players)
		{
			if (!ReadyForComplete[Player])
				return;
		}

		CompleteInteraction();
	}

	private void CompleteInteraction()
	{
		bWaitingForComplete = false;
		for (auto Player : Game::Players)
		{
			ExitFromInteraction(Player, bPlayExitAnimationOnCompleted);
			ReadyForComplete[Player] = false;
		}

		OnDoubleInteractionCompleted.Broadcast();

		if (HasControl())
			NetSetFirstInteractor(nullptr);
	}

	// Only runs ot the player's control side
	void CancelPressed_ControlSide(AHazePlayerCharacter Player)
	{
		if (CanPlayerCancelInteraction(Player))
			NetCancelInteraction(Player);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetCancelInteraction(AHazePlayerCharacter Player)
	{
		CancelInteraction(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkReady(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = true;
		VOBarkTriggerComponent.SetBarker(Player);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnEnded(); // Two inteacting
		else
			VOBarkTriggerComponent.OnStarted(); // We're the only one
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCancel(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		BarkReady[Player.Player] = false;
		VOBarkTriggerComponent.SetBarker(Player.OtherPlayer);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnStarted(); // They're the only one
		else
			VOBarkTriggerComponent.OnEnded(); // Noone interacting
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCompleted()
	{
		// Bark can now safely expire.
		VOBarkTriggerComponent.bRepeatForever = false;
		VOBarkTriggerComponent.TriggerCount = VOBarkTriggerComponent.MaxTriggerCount;
		VOBarkTriggerComponent.OnEnded();
	}

	UFUNCTION(NotBlueprintCallable)
	void BarkTriggered(AHazeActor Barker)
	{
		OnVOBarkTriggered.Broadcast(Cast<AHazePlayerCharacter>(Barker));
	}

	// Overrides for subclasses
	void OnEnterAnimationStarted(AHazePlayerCharacter Player) {}
	void OnMHAnimationStarted(AHazePlayerCharacter Player) {}
	void OnAnimationsStopped(AHazePlayerCharacter Player) {}
	void OnExitAnimationStarted(AHazePlayerCharacter Player) {}
};
