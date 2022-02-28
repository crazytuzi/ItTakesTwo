enum EBoardgamePlatformColor
{  
    Yellow,
    Green,
    Blue,
    Red
};

class ABoardgamePlatform : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent PlatformRoot;

    UPROPERTY(DefaultComponent, Attach = PlatformRoot)
    UStaticMeshComponent PlatformMesh;
    default PlatformMesh.RelativeLocation = FVector(-292.f, 0.f, 60.f);
    default PlatformMesh.SetWorldScale3D(FVector(1.3f, 1.3f, 3.f)); 

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UBoxComponent BoxCollision;
    default BoxCollision.RelativeLocation = FVector(225.f, 0.f, 6.f);
    default BoxCollision.BoxExtent = FVector(225.f, 225.f, 20.f);

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    USceneComponent AttachComponent;
    default AttachComponent.RelativeLocation = FVector(225.f, 0.f, 6.f);

    UPROPERTY()
    FHazeTimeLike BounceTimeline;

    UPROPERTY()
    float BounceTimelineDuration;
    default BounceTimelineDuration = .6f;

    UPROPERTY()
    float BounceAmount;
    default BounceAmount = 20.f;

    UPROPERTY()
    TArray<UMaterialInterface> MaterialArray;

    UPROPERTY()
    EBoardgamePlatformColor PlatformColor;

    UPROPERTY()
    float MaxDegreesToRotate;
    default MaxDegreesToRotate = 10.f;

    UPROPERTY()
    float InterpSpeed;
    default InterpSpeed = 2.f;

    UPROPERTY()
    bool bShouldTilt;
    default bShouldTilt = true;

    UPROPERTY()
    bool bShouldBounce;
    default bShouldBounce = true;

    UPROPERTY()
    bool bMaterialOverride;
    default bMaterialOverride = false;

    // Used if we should attach something to this actor
    // So the attached actor is following the rotation
    UPROPERTY()
    AActor ActorToAttach;

	// Make an array of these instead!!
	UPROPERTY()
	AActor SecondActorToAttach;
    
    UPROPERTY()
    TArray<AActor> PlayerArray;
    
    UPROPERTY()
    FVector PlatformInitialLocation;

    UPROPERTY()
    FVector PlatformIntialWorldLocation;
    
    FRotator TargetRotation;
    FRotator RotationLastTick;
    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

        BounceTimeline.BindUpdate(this, n"BounceTimelineUpdate");
        //BounceTimeline.BindFinished(this, n"BounceTimelineFinished");
        BounceTimeline.SetPlayRate(1 / BounceTimelineDuration);

        PlatformInitialLocation = PlatformRoot.RelativeLocation;
        PlatformIntialWorldLocation = GetActorLocation();

        if (ActorToAttach != nullptr)
        {
            ActorToAttach.AttachToComponent(AttachComponent, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
        }

		if (SecondActorToAttach != nullptr)
			SecondActorToAttach.AttachToComponent(AttachComponent, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			

        //SetActorTickEnabled(false);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if (bShouldTilt)
        {
            if (PlayerArray.Num() >= 1)
            {
                TargetRotation = GetTiltRotation();
            } else
                {
                TargetRotation = FRotator(0,0,0);
            }

            if (bShouldTilt)
            {
                PlatformRoot.SetRelativeRotation(FRotator (FMath::RInterpTo(PlatformRoot.RelativeRotation, TargetRotation, ActorDeltaSeconds, InterpSpeed)));
                RotationLastTick = PlatformRoot.RelativeRotation;
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (!bMaterialOverride)
            PlatformMesh.SetMaterial(0, MaterialArray[PlatformColor]);
    }

    UFUNCTION()
    void BounceTimelineUpdate(float CurrentValue)
    {
        PlatformRoot.SetRelativeLocation(FVector(FMath::VLerp(PlatformInitialLocation, FVector(PlatformInitialLocation - FVector(0.f, 0.f, BounceAmount)), FVector(0,0,CurrentValue))));
    }

    UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
        {
            PlayerArray.AddUnique(OtherActor);

            if (bShouldBounce)
                BounceTimeline.PlayFromStart();
        }
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
        {
            PlayerArray.Remove(OtherActor);
            
            if (bShouldBounce)
                BounceTimeline.PlayFromStart();
        }
    }

    FRotator GetTiltRotation()
    {
        FRotator NewRotation;

        for (AActor OverlappingPlayer : PlayerArray)
        {
            FVector YDirection = FVector(OverlappingPlayer.GetActorLocation() - Root.GetWorldLocation());
            YDirection.Normalize();
            float YDot = YDirection.DotProduct(GetActorRightVector());
            YDot = YDot * 10.0f;

            FVector XDirection = FVector(OverlappingPlayer.GetActorLocation() - Root.GetWorldLocation());
            XDirection.Normalize();
            float XDot = XDirection.DotProduct(GetActorForwardVector());
            XDot = XDot * -10.0f;

            float YDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-9.0f, 9.0f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), YDot);
            float XDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-9.0f, 9.0f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), XDot);

            NewRotation += FRotator(XDotMapped, 0.0f, YDotMapped);
        }
        return NewRotation;
    }
}