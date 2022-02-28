import Cake.LevelSpecific.Hopscotch.FidgetSpinner;

class ABalloonPillar : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent BalloonMesh;
    default BalloonMesh.RelativeLocation = FVector(0.f, 0.f, 2020.f);
    default BalloonMesh.RelativeScale3D = FVector(1.7f, 1.7f, 1.7f);

    UPROPERTY(DefaultComponent, Attach = BalloonMesh)
    UStaticMeshComponent StringMesh;
    default StringMesh.RelativeLocation = FVector(0.f, 0.f, -1810.f);
    default StringMesh.RelativeScale3D = FVector(0.15f, 0.15f, 30.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PillarMesh;
    default PillarMesh.RelativeLocation = FVector(0.f, 0.f, -2910.f);
    default PillarMesh.RelativeScale3D = FVector(5.f, 5.f, 46.f);

    UPROPERTY(DefaultComponent, Attach = BalloonMesh)
    UBoxComponent BoxCollision;
    default BoxCollision.BoxExtent = FVector(200.f, 200.f, 280.f);

    UPROPERTY()
    FHazeTimeLike DropPillarTimeline;
    default DropPillarTimeline.Duration = 1.f;

    UPROPERTY()
    float TargetDropZValue;
    default TargetDropZValue = 2000.f;

    UPROPERTY()
    float TimelineDuration;

    UPROPERTY()
    UNiagaraSystem BalloonPopFX;

    FVector PillarInitialWorldLocation;
    bool bHasPopped;
    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggeredOverlap");
        DropPillarTimeline.BindUpdate(this, n"DropPillarTimelineUpdate");

        PillarInitialWorldLocation = PillarMesh.GetWorldLocation();

        DropPillarTimeline.SetPlayRate(1 / TimelineDuration);
    }

    UFUNCTION()
    void OnTriggeredOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        if (Cast<AFidgetSpinner>(OtherActor) != nullptr && !bHasPopped)
        {
            bHasPopped = true;
            DropPillarTimeline.PlayFromStart();
            Niagara::SpawnSystemAtLocation(BalloonPopFX, BalloonMesh.GetWorldLocation(), FRotator::ZeroRotator);
            BalloonMesh.SetVisibility(false);
            StringMesh.SetVisibility(false);
        }
    }

    UFUNCTION()
    void DropPillarTimelineUpdate(float CurrentValue)
    {
        DropPillar(CurrentValue);
    }

    void DropPillar(float LerpValue)
    {
        PillarMesh.SetWorldLocation(FMath::VLerp(PillarInitialWorldLocation, 
            FVector(PillarInitialWorldLocation + FVector(0.f, 0.f, -TargetDropZValue)), 
            FVector(LerpValue, LerpValue, LerpValue)));
    }
}