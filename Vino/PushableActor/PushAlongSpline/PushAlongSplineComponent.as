delegate void FPushSplineDelegate(AHazePlayerCharacter Player);

class UPushAlongSplineComponent : UActorComponent
{
    FPushSplineDelegate Activated;
    FPushSplineDelegate Deactivated;

    TArray<FTransform> CurrentInteractionPoints;

    AHazePlayerCharacter PlayerOwner;
    UAnimSequence PushAnimation;

    bool bTriggerIsActivated = false;
    
    
    //Dual Push
    AHazePlayerCharacter OtherPlayer;
    UObject CurrentTrigger;
    bool bRequiresBothPlayers = false;
    bool bCanOperate = false;

    FVector OtherPlayer_MovementVector;
    FVector OtherPlayer_Offset;
    int CurrentLockedIndex;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        OtherPlayer = PlayerOwner.GetOtherPlayer();
    }

    UFUNCTION()
    void TriggerActivated(const TArray<FTransform>& PointsArray)
    {
        CurrentInteractionPoints = PointsArray;
        bTriggerIsActivated = true;
    }

    UFUNCTION()
    void TriggerDeactivated()
    {
        PushAnimation = nullptr;
        CurrentTrigger = nullptr;
        CurrentInteractionPoints.Empty();
        bTriggerIsActivated = false;
    }

    void OnCapabilityActivated()
    {
        Activated.ExecuteIfBound(Cast<AHazePlayerCharacter>(GetOwner()));
    }

    void OnCapabilityDeactivated()
    {
        Deactivated.ExecuteIfBound(Cast<AHazePlayerCharacter>(GetOwner()));
        bCanOperate = false;
    }

    //Dual Push
    UFUNCTION()
    bool CanOperate()
    {
        return bCanOperate;
    }

    void SetOtherPlayersMovementVector(FVector Movement)
    {
        UPushAlongSplineComponent OtherPlayerComponent = Cast<UPushAlongSplineComponent>(PlayerOwner.GetOtherPlayer().GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(OtherPlayerComponent != nullptr)
        {
            OtherPlayerComponent.OtherPlayer_MovementVector = Movement;
        }
    }

    void SetOtherPlayersOffset(FVector Offset)
    {
        UPushAlongSplineComponent OtherPlayerComponent = Cast<UPushAlongSplineComponent>(PlayerOwner.GetOtherPlayer().GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(OtherPlayerComponent != nullptr)
        {
            OtherPlayerComponent.OtherPlayer_Offset = Offset;
        }
    }

    FVector GetOtherPlayersOffset()
    {
        return OtherPlayer_Offset;
    }

    FVector GetOtherPlayerInput()
    {
        return OtherPlayer_MovementVector;
    }

    void SetTrigger(UObject Trigger)
    {
        CurrentTrigger = Trigger;
    }

    bool IsOtherPlayerReady()
    {
        UPushAlongSplineComponent OtherPlayerComponent = Cast<UPushAlongSplineComponent>(PlayerOwner.GetOtherPlayer().GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(OtherPlayerComponent != nullptr)
        {
            if(OtherPlayerComponent.CurrentTrigger != CurrentTrigger)
            {
                return false;
            }

            if(OtherPlayerComponent.CanOperate())
            {
                return true;
            }
        }

        return false;
    }

    const int GetLockedIndex() const
    {
        UPushAlongSplineComponent OtherPlayerComponent = Cast<UPushAlongSplineComponent>(PlayerOwner.GetOtherPlayer().GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(OtherPlayerComponent != nullptr)
        {
            if(OtherPlayerComponent.CurrentTrigger != CurrentTrigger)
            {
                return -1;
            }

            return OtherPlayerComponent.CurrentLockedIndex;
        }

        return -1;
    }
}