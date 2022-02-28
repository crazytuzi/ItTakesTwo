class ATiltingPlatform : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PlatformMesh;

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UStaticMeshComponent Wall01;

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UStaticMeshComponent Wall02;

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UStaticMeshComponent Wall03;

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UStaticMeshComponent Wall04;

    UPROPERTY(DefaultComponent, Attach = PlatformMesh)
    UBoxComponent BoxCollision;

    UPROPERTY()
    float MaxDegreesToRotate;
    default MaxDegreesToRotate = 6.0f;

    UPROPERTY()
    float RotationInterpSpeed;
    default RotationInterpSpeed = 1.0f;

    UPROPERTY()
    bool bShouldOnlyTiltSideways;

    FRotator TargetRotation;

    FRotator RotationLastTick;

    FHazeAcceleratedRotator AcceleratedRot; 

    TArray<AActor> PlayersOnPlatform;



    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxBeginOverlap");
        BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxEndOverlap");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        PlatformMesh.SetRelativeRotation(AcceleratedRot.AccelerateTo(GetTiltRotation(), RotationInterpSpeed, ActorDeltaSeconds));

        RotationLastTick = PlatformMesh.RelativeRotation;
    }

    UFUNCTION()
    void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
       UPrimitiveComponent OtherComponent, int OtherBodyIndex,
       bool bFromSweep, FHitResult& Hit)
       {
           if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
           {
               PlayersOnPlatform.AddUnique(OtherActor);
           }
       }

    UFUNCTION()
    void BoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
       UPrimitiveComponent OtherComponent, int OtherBodyIndex)
       {
           if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
           {
               PlayersOnPlatform.Remove(OtherActor);
           }
       }

       // Gets the direction from the PlatformMesh origin to the player
       // Only X and Y direction are considered here.
       FVector GetPlayerDirection(AActor Player)
       {
           float DirectionX = Player.GetActorLocation().X - PlatformMesh.GetWorldLocation().X;
           float DirectionY = Player.GetActorLocation().Y - PlatformMesh.GetWorldLocation().Y;

           FVector Direction = FVector(DirectionX, DirectionY, 0.0f);
           Direction.Normalize();

           return Direction;
       }

       FRotator GetTiltRotation()
       {
           TargetRotation = FRotator::ZeroRotator;

        for (int i = 0, c = PlayersOnPlatform.Num(); i < c; i++)
        {
            FVector YDirection = FVector(PlayersOnPlatform[i].GetActorLocation() - PlatformMesh.GetWorldLocation());
            //YDirection.Normalize();
            float YDot = YDirection.DotProduct(PlatformMesh.GetRightVector());
            YDot = YDot * 1.0f;

            FVector XDirection = FVector(PlayersOnPlatform[i].GetActorLocation() - PlatformMesh.GetWorldLocation());
            float XDot = XDirection.DotProduct(PlatformMesh.GetForwardVector());
            XDot = XDot * -1.0f;

            float YDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-2100.f, 2100.f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), YDot);
            float XDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-2100.f, 2100.f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), XDot);       

            if (bShouldOnlyTiltSideways)
                TargetRotation = TargetRotation.Compose(FRotator(XDotMapped, 0.0f, 0.0f));

            else 
                TargetRotation = TargetRotation.Compose(FRotator(XDotMapped, 0.0f, YDotMapped));
        }

        return TargetRotation;
       }
}