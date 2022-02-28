/*
FHazeTimeLike can be used to emulate timeline behavior from script or outside of actors.
 */
class AExampleTimeLikeActor : AHazeActor
{
    // Setting it as a property allows any child blueprint classes to set settings, such as the curve
    UPROPERTY()
    FHazeTimeLike Timeline;

    // We can provide some defaults ourselves as well
    default Timeline.Duration = 2.f;

    // A looping timeline wraps back to the beginning after reaching the end
    default Timeline.bLoop = true;

    // A flip-flopping timeline goes back and forth between the start and end, reversing as needed
    default Timeline.bFlipFlop = true;

    // We can set automatic networking on timelikes. The sync tag used must be unique within the object it's in
    default Timeline.bSyncOverNetwork = true;
    default Timeline.SyncTag = n"ExampleTimeline";

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // We can bind update and finished functions to the timeline, so we get events when needed
        Timeline.BindUpdate(this, n"OnTimelineUpdated");
        Timeline.BindFinished(this, n"OnTimelineFinished");
        // Note that any functions you bind here must be UFUNCTION()s

        Timeline.Play();
        //Timeline.PlayFromStart();
        //Timeline.ReverseFromEnd();
    }

    UFUNCTION()
    void DoReverseTimeline()
    {
        Timeline.Reverse();
    }

    UFUNCTION()
    void OnTimelineUpdated(float CurrentValue)
    {
        Print("Timeline Update: "+CurrentValue);

        // We can also access the properties of the timeline directly:
        Print("Current value: "+Timeline.GetValue());
        Print("Is timeline reversed? "+Timeline.IsReversed());
        Print("Is timeline playing? "+Timeline.IsPlaying());
    }

    UFUNCTION()
    void OnTimelineFinished(float CurrentValue)
    {
        Print("Timeline Finished: "+CurrentValue);
    }
}