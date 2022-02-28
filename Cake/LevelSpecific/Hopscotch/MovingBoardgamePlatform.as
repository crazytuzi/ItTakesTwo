import Cake.LevelSpecific.Hopscotch.BoardgamePlatform;

class AMovingBoardgamePlatform : ABoardgamePlatform
{
    UPROPERTY()
    FHazeTimeLike MovePlatformTimeline;
    default MovePlatformTimeline.bLoop = true;
    default MovePlatformTimeline.Duration = 4.f;

    UPROPERTY()
    float TargetZValue;

    UPROPERTY()
    float TimelineStartDelay;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ABoardgamePlatform::BeginPlay_Implementation();
        MovePlatformTimeline.BindUpdate(this, n"MovePlatformTimelineUpdate");
        StartTimelineTimer();
    }

    UFUNCTION()
    void StartTimelineTimer()
    {
        if (TimelineStartDelay > 0)
            System::SetTimer(this, n"StartTimeline", TimelineStartDelay, false);

        else 
            StartTimeline();
    }

    UFUNCTION()
    void StartTimeline()
    {
        MovePlatformTimeline.PlayFromStart();
    }

    UFUNCTION()
    void MovePlatformTimelineUpdate(float CurrentValue)
    {
        SetActorLocation(FMath::VLerp(PlatformIntialWorldLocation, 
        FVector(PlatformIntialWorldLocation.X, PlatformIntialWorldLocation.Y, 
        PlatformIntialWorldLocation.Z - TargetZValue), FVector(CurrentValue, CurrentValue, CurrentValue)));
    }
}