import Vino.Interactions.ScriptInteractionBase;

event void FTriggerEvent(AHazePlayerCharacter Player, ATriggerInteraction Interaction);

class ATriggerInteraction : AScriptInteractionBase
{
    /* Executed when the interaction first triggers. */
    UPROPERTY(Category = "Trigger Interaction")
    FTriggerEvent OnTriggerActivated;

    /* Override of OnTriggerActivated() from AHazeInteractionActor, called when the player hits a button. */
    UFUNCTION(NotBlueprintCallable, BlueprintOverride)
    void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
    {
        OnTriggerActivated.Broadcast(Player, this);
    }
};