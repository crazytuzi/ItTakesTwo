class AGumballMachineCamera : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeCameraComponent CameraComponent;

    UPROPERTY(DefaultComponent, Attach = CameraComponent)
    UArrowComponent Arrow;

    UPROPERTY()
    bool bShouldFocusOnPlayer;
    
    UPROPERTY()
    AHazePlayerCharacter PlayerRef;
    
    FVector InitialLocation;
    float CameraInterpSpeed;
    FHazeCameraBlendSettings BlendSettings (2.0f);

    default CameraComponent.RelativeLocation = FVector(2500.f, 0.f, 600.f);
    default CameraComponent.RelativeRotation = FRotator(0.f, -10.f, 180.f);
    default CameraInterpSpeed = 3.0f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        InitialLocation = GetActorLocation();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if (bShouldFocusOnPlayer)
        {
            SetActorLocation(FVector(FMath::VInterpTo(GetActorLocation(), GetInterpTargetLocation(), GetActorDeltaSeconds(), CameraInterpSpeed)));
            SetActorRotation(FRotator(FMath::RInterpTo(GetActorRotation(), GetInterpTargetRotation(), GetActorDeltaSeconds(), CameraInterpSpeed)));
        }
    }

    FVector GetInterpTargetLocation()
    {        
        FVector TargetLoc = FVector(InitialLocation.X, InitialLocation.Y, PlayerRef.GetActorLocation().Z);
        return TargetLoc;
    }
    
    FRotator GetInterpTargetRotation()
    {
        FVector Direction = FVector(PlayerRef.GetActorLocation() - GetActorLocation());
        Direction.Normalize();

        FRotator TargetRot = Direction.ToOrientationRotator();

        return TargetRot;
    }

    UFUNCTION()
    void ActivateGumballMachineCamera(AHazePlayerCharacter Player)
    {
        if (!bShouldFocusOnPlayer)
        {
            PlayerRef = Player;
            bShouldFocusOnPlayer = true;
        
            Player.ActivateCamera(CameraComponent, BlendSettings);
        }
    }

    UFUNCTION()
    void DeactivateGumballMachineCamera(AHazePlayerCharacter Player)
    {
        bShouldFocusOnPlayer = false;
        Player.DeactivateCamera(CameraComponent);
        PlayerRef = nullptr;
    }
}