import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Spline.SplineComponent;
import Vino.PushableActor.PushAlongSpline.PushAlongSplineCapability;
import Vino.PushableActor.PushAlongSplineDual.PushAlongSplineDualCapability;
import Vino.PushableActor.PushAlongSpline.PushAlongSplineComponent;
import Vino.Movement.MovementSystemTags;

class APushAlongSplineTrigger : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::Black);
    default RootComponent.Mobility = EComponentMobility::Movable;

     //Actor that will be moved.
    UPROPERTY(BlueprintReadWrite, Attach = RootComponent)
    AActor PushableActor;
    
    UPROPERTY(BlueprintReadOnly, DefaultComponent, Attach = RootComponent)
    UHazeSplineComponent SplineComponent;

    UPROPERTY(EditInstanceOnly)
    UAnimSequence PushAnimation;

    UPROPERTY(EditInstanceOnly, ShowOnActor, Category = "Settings", meta =(MakeEditWidget))
    TArray<FTransform> InteractionPoints;

    //Resistance on object being pushed. Range 0-1
    UPROPERTY()
    float Resistance = 0;

    UPROPERTY()
    bool bRequiresBothPlayers = false;

    FVector OriginalOffset;

     //Players currently in Volume.
    AHazePlayerCharacter CurrentInteractingPlayer;

    bool bTriggerForMayInternal;
    bool bTriggerForCodyInternal;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        Resistance = FMath::Clamp(Resistance, 0.f, 1.f);

        if(PushableActor != nullptr)
        {
            AttachToComponent(PushableActor.RootComponent);
        }
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FVector Location = GetActorLocation();

        OriginalOffset = GetActorLocation() - PushableActor.GetActorLocation();
        DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
        SplineComponent.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

        UPushAlongSplineComponent::GetOrCreate(Game::GetMay());
        UPushAlongSplineComponent::GetOrCreate(Game::GetCody());

        if(bRequiresBothPlayers)
        {
            Capability::AddPlayerCapabilityRequest(UPushAlongSplineDualCapability::StaticClass());
        }
        else
        {
            Capability::AddPlayerCapabilityRequest(UPushAlongSplineCapability::StaticClass());
        }

		Super::BeginPlay();
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(bRequiresBothPlayers)
        {
            Capability::RemovePlayerCapabilityRequest(UPushAlongSplineDualCapability::StaticClass());
        }
        else
        {
            Capability::RemovePlayerCapabilityRequest(UPushAlongSplineCapability::StaticClass());
        }
	}

    void EnterTrigger(AActor Actor) override
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
        if(Player.IsAnyCapabilityActive(n"PickupCapability") || Player.IsAnyCapabilityActive(n"PushObject"))
        {
            return;
        }

        Player.BlockCapabilities(MovementSystemTags::Dash, this);

        Player.SetCapabilityAttributeObject(n"ActorToMove", PushableActor);
        Player.SetCapabilityAttributeObject(n"Spline", SplineComponent);
        Player.SetCapabilityAttributeValue(n"SplineResistance", Resistance);

        UPushAlongSplineComponent PushAlongSplineComponent = Cast<UPushAlongSplineComponent>(Player.GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(SplineComponent != nullptr)
        {
            PushAlongSplineComponent.TriggerActivated(InteractionPoints);
            PushAlongSplineComponent.bRequiresBothPlayers = bRequiresBothPlayers;
            PushAlongSplineComponent.PushAnimation = PushAnimation;
            PushAlongSplineComponent.Activated.BindUFunction(this, n"BeginInteraction");
            PushAlongSplineComponent.Deactivated.BindUFunction(this, n"EndInteraction");
            if(bRequiresBothPlayers)
            {
                PushAlongSplineComponent.SetTrigger(this);
            }
        }
    }

    void LeaveTrigger(AActor Actor) override
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
        if(CurrentInteractingPlayer == Player)
        {
            return;
        }

        if(Player.IsAnyCapabilityActive(n"PickupCapability"))
        {
            return;
        }

        Player.UnblockCapabilities(MovementSystemTags::Dash, this);

        UPushAlongSplineComponent PushAlongSplineComponent = Cast<UPushAlongSplineComponent>(Player.GetComponentByClass(UPushAlongSplineComponent::StaticClass()));
        if(PushAlongSplineComponent != nullptr)
        {
            PushAlongSplineComponent.TriggerDeactivated();
            PushAlongSplineComponent.Activated.Clear();
            PushAlongSplineComponent.Deactivated.Clear();
        }
    }

    UFUNCTION()
    void BeginInteraction(AHazePlayerCharacter Player)
    {
        if(!bRequiresBothPlayers)
        {
            if(IsOverlappingActor(Player.GetOtherPlayer()))
            {   
                LeaveTrigger(Player.GetOtherPlayer());
            }
        }

        LockInteraction(Player);

        CurrentInteractingPlayer = Player;
    }

    UFUNCTION()
    void EndInteraction(AHazePlayerCharacter Player)
    {
        CurrentInteractingPlayer = nullptr;
        UnLockInteraction(Player);
        SetActorLocation(PushableActor.GetActorLocation() + OriginalOffset);
    }

    void LockInteraction(AHazePlayerCharacter Player)
    {
        if(bRequiresBothPlayers)
        {
            if(Player.IsMay())
            {
                bTriggerForMayInternal = bTriggerForMay;
                bTriggerForMay = false;
            }
            else
            {
                bTriggerForCodyInternal = bTriggerForCody;
                bTriggerForCody = false;
            }

            return;
        }

        bTriggerForMayInternal = bTriggerForMay;
        bTriggerForCodyInternal = bTriggerForCody;

        bTriggerForMay = false;
        bTriggerForCody = false;
    }

    void UnLockInteraction(AHazePlayerCharacter Player)
    {
        if(bRequiresBothPlayers)
        {
            if(Player.IsMay())
            {
                bTriggerForMay = bTriggerForMayInternal;
            }
            else
            {
                bTriggerForCody = bTriggerForCodyInternal;
            }
        }
        else
        {
            bTriggerForMay = bTriggerForMayInternal;
            bTriggerForCody = bTriggerForCodyInternal;
        }

        //Update Overlaps
        if(!IsOverlappingActor(Player))
        {
            LeaveTrigger(Player);
        }
    }
}
