import Cake.LevelSpecific.Hopscotch.FallingPillar;

class AFallingPillarController : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY()
    TArray<AFallingPillar> FallingPillarArray;

    UPROPERTY()
    float MovePillarInterval;

    int PillarLowerIndex;
    int PillarIndexMax;

    default MovePillarInterval = 1.0f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PillarIndexMax = FallingPillarArray.Num() - 1;
        System::SetTimer(this, n"LowerPillar", MovePillarInterval, bLooping = true);

        for (int i = 0; i < FallingPillarArray.Num(); i++)
        {
            FallingPillarArray[i].RaiseTimer = MovePillarInterval;
        }

    }

    UFUNCTION()
    void LowerPillar()
    {
        FallingPillarArray[PillarLowerIndex].LowerPillar();
        PillarLowerIndex++;

        if (PillarLowerIndex > PillarIndexMax)
        {
            PillarLowerIndex = 0;
        }
    }
}