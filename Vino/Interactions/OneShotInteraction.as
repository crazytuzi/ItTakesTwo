import Vino.Animations.OneShotAnimation;
import Vino.Animations.LockIntoAnimation;

import Vino.Interactions.ScriptInteractionBase;

event void FOneShotEvent(AHazePlayerCharacter Player, AOneShotInteraction Interaction);

class AOneShotInteraction : AScriptInteractionBase
{
    UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
    FOneShotAnimationSettings Animation;

    /* Executed when the interaction first triggers. */
    UPROPERTY(Category = "One Shot Interaction")
    FOneShotEvent OnOneShotActivated;

    /* Executed when the one shot animation for this interaction has finished blending in. */
    UPROPERTY(Category = "One Shot Interaction")
    FOneShotEvent OnOneShotBlendedIn;

    /* Executed when the one shot animation for this interaction has finished playing and has started blending out. */
    UPROPERTY(Category = "One Shot Interaction")
    FOneShotEvent OnOneShotBlendingOut;

	// Audio Event
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OneShotActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayOneShotActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyOneShotActivatedAudioEvent;

    // The actor that is currently playing the oneshot
    AHazePlayerCharacter ActivePlayer;

    /* Override of OnTriggerComponentActivated() from AHazeInteractionActor, called when the player hits a button. */
    UFUNCTION(NotBlueprintCallable, BlueprintOverride)
    void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
    {
        // We could still be in this interaction on this side
        if (ActivePlayer != nullptr)
            EndInteraction();

        // Disable the trigger while the oneshot is actively playing
        TriggerComponent.Disable(n"OneShotPlaying");
        LockIntoAnimation(Player, this);

        // Tell anything bound to us that we've started playing
        ActivePlayer = Player;
        OnOneShotActivated.Broadcast(Player, this);

		// Play Audio Event
		Player.PlayerHazeAkComp.HazePostEvent(OneShotActivatedAudioEvent);
		if (Player.IsMay())
			Player.PlayerHazeAkComp.HazePostEvent(MayOneShotActivatedAudioEvent);
		else
			Player.PlayerHazeAkComp.HazePostEvent(CodyOneShotActivatedAudioEvent);

        // Actually play the animation
        FOneShotAnimationEvents Events;
        Events.OnBlendedIn.BindUFunction(this, n"AnimationBlendedIn");
        Events.OnBlendingOut.BindUFunction(this, n"AnimationBlendingOut");
        PlayOneShotAnimation(Player, Animation, Events);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationBlendedIn()
    {
        OnOneShotBlendedIn.Broadcast(ActivePlayer, this);
    }

    UFUNCTION(NotBlueprintCallable)
    void AnimationBlendingOut()
    {
        AHazePlayerCharacter PreviousPlayer = ActivePlayer;

        // Re-enable the trigger with the same tag that we disabled it with
        ActivePlayer = nullptr;
        TriggerComponent.Enable(n"OneShotPlaying");
        UnlockFromAnimation(PreviousPlayer, this);

        // Tell anything bound to us that we've started blending out
        OnOneShotBlendingOut.Broadcast(PreviousPlayer, this);
    }

    void EndInteraction()
    {
        ActivePlayer.StopAnimation(BlendTime = Animation.BlendTime);
        ensure(ActivePlayer == nullptr);
    }
};