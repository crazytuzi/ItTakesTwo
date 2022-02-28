import Cake.LevelSpecific.Hopscotch.MovingPillow;

class AMovingPillowManager : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY()
    TArray<AMovingPillow> MovingPillowArray;

    UPROPERTY()
    float MoveInterval;

    UPROPERTY()
    float TimelineDuration;

    int Index;
    int IndexMax;
    FTimerHandle PillowTimerHandle;

    default TimelineDuration = 3.0f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        IndexMax = MovingPillowArray.Num();
    }

    UFUNCTION()
    void StartMovePillowsTimer()
    {
        PillowTimerHandle =  System::SetTimer(this, n"MovePillows", MoveInterval, bLooping = true);
    }

    UFUNCTION()
    void MovePillows()
    {
        if (Index < IndexMax && MovingPillowArray.Num() != 0)
        {
            MovingPillowArray[Index].MovePillow(TimelineDuration);
            Index++;
        }
        else
        {
            System::ClearAndInvalidateTimerHandle(PillowTimerHandle);
            Index = 0;
        }
    }
}