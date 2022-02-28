UCLASS(HideCategories = "Rendering Tags Activation Cooking Physics LOD AssetUserData Collision")
class UMoveActorOverTimeComponent : USceneComponent
{
    UPROPERTY()
    bool bActiveFromStart = false;

    UPROPERTY()
    bool bSaveTargetOnStart = false;
    
    UPROPERTY(meta = (MakeEditWidget))
    FTransform RelativeTargetTransform;
    FTransform TargetTransform;

    UPROPERTY()
    FHazeTimeLike MovementSettings;
    default MovementSettings.Duration = 1.f;

    FTransform StartTransform;

    bool bHasMoved = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        MovementSettings.BindUpdate(this, n"OnTimelineUpdated");
        MovementSettings.BindFinished(this, n"OnTimelineFinished");

        if (bSaveTargetOnStart)
            CalculateTargetTransform();

        if (bActiveFromStart)
            StartMovingActor();
    }

    void CalculateTargetTransform()
    {
        TargetTransform.Location = Owner.ActorTransform.TransformPosition(RelativeTargetTransform.Location);
        TargetTransform.SetRotation(Owner.ActorTransform.TransformRotation(RelativeTargetTransform.GetRotation()));
    }

    UFUNCTION()
    void StartMovingActor()
    {
        if (!bHasMoved)
        {
            bHasMoved = true;
            StartTransform = Owner.ActorTransform;
            if (!bSaveTargetOnStart)
                CalculateTargetTransform();
            
            MovementSettings.Play();
        }
    }

    UFUNCTION()
    void OnTimelineUpdated(float CurrentValue)
    {
        FVector TargetLocation = FMath::Lerp(StartTransform.Location, TargetTransform.Location, CurrentValue);
        FQuat TargetRotation = FQuat::FastLerp(StartTransform.GetRotation(), TargetTransform.GetRotation(), CurrentValue);

        FTransform CurrentTransform = FTransform(TargetRotation, TargetLocation, Owner.GetActorScale3D());
        Owner.SetActorTransform(CurrentTransform);
    }

    UFUNCTION()
    void OnTimelineFinished(float CurrentValue)
    {

    }
}