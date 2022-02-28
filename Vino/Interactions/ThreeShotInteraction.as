
import Vino.Animations.ThreeShotAnimation;
import Vino.Animations.LockIntoAnimation;

import Vino.Interactions.ScriptInteractionBase;
import Vino.Tutorial.TutorialStatics;

event void FThreeShotEvent(AHazePlayerCharacter Player, AThreeShotInteraction Interaction);

class AThreeShotInteraction : AScriptInteractionBase
{
    UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
    FThreeShotAnimationSettings Animation;

	UPROPERTY(Category = "Three Shot Interaction")
	bool bShowCancelPrompt = true;

	UPROPERTY(Category = "Three Shot Interaction", Meta = (InlineEditConditionToggle))
	bool bOverrideCancelText = false;

	UPROPERTY(Category = "Three Shot Interaction", Meta = (EditCondition = "bOverrideCancelText"))
	FText OverrideCancelText;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnThreeShotActivated;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnStartBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnStartBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnMHBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnMHTick;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnMHBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnEndBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnEndBlendingOut;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayEnterInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyEnterInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayExitInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyExitInteractionAudioEvent;

    // The actor that is currently playing the threeshot
    AHazePlayerCharacter ActivePlayer;

    // The current three-shot that is being played
    UThreeShotAnimation CurrentAnimation;

    /* Override of OnTriggerComponentActivated() from AHazeInteractionActor, called when the player hits a button. */
    UFUNCTION(NotBlueprintCallable, BlueprintOverride)
    void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
    {
        // We could still be in this interaction on this side
        if (ActivePlayer != nullptr)
            EndInteraction();

        // Disable the trigger while the oneshot is actively playing
        TriggerComponent.Disable(n"ThreeShotPlaying");
        LockPlayerIntoAnimation(Player); 

        // Tell anything bound to us that we've started playing
        ActivePlayer = Player;
        OnThreeShotActivated.Broadcast(Player, this);

		if (bShowCancelPrompt && Animation.bCanPlayerCancel && Animation.bCanCancelDuringEnter)
		{
			if (bOverrideCancelText)
				Player.ShowCancelPromptWithText(this, OverrideCancelText);
			else
				Player.ShowCancelPrompt(this);
		}

		StartAnimation(Player);
    }

	void LockPlayerIntoAnimation(AHazePlayerCharacter Player)
	{
		LockIntoAnimation(Player, this);
	}

	void StartAnimation(AHazePlayerCharacter Player)
	{
        // Actually play the animation
        FThreeShotAnimationEvents Events;;
        Events.OnStartBlendedIn.BindUFunction(this, n"AnimationStartBlendedIn");
        Events.OnStartBlendingOut.BindUFunction(this, n"AnimationStartBlendingOut");
        Events.OnMHBlendedIn.BindUFunction(this, n"AnimationMHBlendedIn");
        Events.OnMHTick.BindUFunction(this, n"AnimationMHTick");
        Events.OnMHBlendingOut.BindUFunction(this, n"AnimationMHBlendingOut");
        Events.OnEndBlendedIn.BindUFunction(this, n"AnimationEndBlendedIn");
        Events.OnEndBlendingOut.BindUFunction(this, n"AnimationEndBlendingOut");
        CurrentAnimation = PlayThreeShotAnimation(Player, Animation, Events);
	}

    UFUNCTION(NotBlueprintCallable)
    void AnimationStartBlendedIn()
    {
        OnStartBlendedIn.Broadcast(ActivePlayer, this);
		
		if (ActivePlayer.IsMay())
			ActivePlayer.PlayerHazeAkComp.HazePostEvent(MayEnterInteractionAudioEvent);
		else
			ActivePlayer.PlayerHazeAkComp.HazePostEvent(CodyEnterInteractionAudioEvent);
		
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationStartBlendingOut()
    {
		if (bShowCancelPrompt && Animation.bCanPlayerCancel && !Animation.bCanCancelDuringEnter)
		{
			if (bOverrideCancelText)
				ActivePlayer.ShowCancelPromptWithText(this, OverrideCancelText);
			else
				ActivePlayer.ShowCancelPrompt(this);
		}

        OnStartBlendingOut.Broadcast(ActivePlayer, this);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationMHBlendedIn()
    {
        OnMHBlendedIn.Broadcast(ActivePlayer, this);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationMHTick()
    {
        OnMHTick.Broadcast(ActivePlayer, this);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationMHBlendingOut()
    {
        OnMHBlendingOut.Broadcast(ActivePlayer, this);
		
		if (ActivePlayer.IsMay())
			ActivePlayer.PlayerHazeAkComp.HazePostEvent(MayExitInteractionAudioEvent);
		else
			ActivePlayer.PlayerHazeAkComp.HazePostEvent(CodyExitInteractionAudioEvent);

    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationEndBlendedIn()
    {
        OnEndBlendedIn.Broadcast(ActivePlayer, this);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationEndBlendingOut()
    {
        AHazePlayerCharacter PreviousPlayer = ActivePlayer;

        // Re-enable the trigger with the same tag that we disabled it with
        ActivePlayer = nullptr;
        CurrentAnimation = nullptr;
        TriggerComponent.EnableAfterFullSyncPoint(n"ThreeShotPlaying");
        UnlockFromAnimation(PreviousPlayer, this);

		if (bShowCancelPrompt)
			PreviousPlayer.RemoveCancelPromptByInstigator(this);

        // Tell anything bound to us that we've started blending out
        OnEndBlendingOut.Broadcast(PreviousPlayer, this);
    }

    UFUNCTION()
	void EndInteraction()
    {
        if (CurrentAnimation != nullptr)
		{
			CurrentAnimation.ForceStop();
			ensure(CurrentAnimation == nullptr);
		}
		ensure(ActivePlayer == nullptr);
    }
};