class AFallingPillar : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PillarMesh;

    UPROPERTY()
    FHazeTimeLike MovePillarTimeline;

    UPROPERTY()
    float MovePillarTimelineDuration;

    UPROPERTY(meta = (MakeEditWidget))
    FVector TargetLoweredLocation;

    FVector InitialLocation;
    FVector TargetLoweredLocationWorld;
    float RaiseTimer;

    default MovePillarTimeline.Duration = 1.0f;
    default MovePillarTimelineDuration = 0.8f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        MovePillarTimeline.BindUpdate(this, n"MovePillarTimelineUpdate");
        MovePillarTimeline.BindFinished(this, n"MovePillarTimelineFinished");


        InitialLocation = GetActorLocation();
        TargetLoweredLocationWorld = GetActorTransform().TransformPosition(TargetLoweredLocation);
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        PillarMesh.SetScalarParameterValueOnMaterials(n"Opacity", 2.f);
    }

    UFUNCTION()
    void MovePillarTimelineUpdate(float CurrentValue)
    {
        SetActorLocation(FVector(FMath::VLerp(InitialLocation, TargetLoweredLocationWorld, FVector(CurrentValue, CurrentValue, CurrentValue))));
    }

    UFUNCTION()
    void MovePillarTimelineFinished(float CurrentValue)
    {
        if (CurrentValue == 1)
        {   
            System::SetTimer(this, n"RaisePillar", RaiseTimer, bLooping = false);
        }
    }

    void LowerPillar()
    {
        MovePillarTimeline.SetPlayRate(1 / MovePillarTimelineDuration);
        MovePillarTimeline.PlayFromStart();
    }

    UFUNCTION()
    void RaisePillar()
    {
        MovePillarTimeline.SetPlayRate(1 / MovePillarTimelineDuration);
        MovePillarTimeline.ReverseFromEnd();
    }
}