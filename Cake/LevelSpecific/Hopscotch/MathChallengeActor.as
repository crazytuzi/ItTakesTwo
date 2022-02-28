import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

class AMathChallengeActor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PlaneMesh;
    default PlaneMesh.bHiddenInGame = true;
    default PlaneMesh.RelativeScale3D = FVector(12.f, 12.f, 1.f);
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh01;
    default Mesh01.RelativeLocation = FVector(-200.f, -200.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh02;
    default Mesh02.RelativeLocation = FVector(200.f, -200.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh03;
    default Mesh03.RelativeLocation = FVector(600.f, -200.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh04;
    default Mesh04.RelativeLocation = FVector(-200.f, 200.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh05;
    default Mesh05.RelativeLocation = FVector(200.f, 200.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh06;
    default Mesh06.RelativeLocation = FVector(600.f, 200.f, 0);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh07;
    default Mesh07.RelativeLocation = FVector(-200.f, 600.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh08;
    default Mesh08.RelativeLocation = FVector(200.f, 600.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh09;
    default Mesh09.RelativeLocation = FVector(600.f, 600.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Mesh01)
    UBoxComponent Box01;
    default Box01.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box01.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh02)
    UBoxComponent Box02;
    default Box02.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box02.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh03)
    UBoxComponent Box03;
    default Box03.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box03.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh04)
    UBoxComponent Box04;
    default Box04.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box04.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh05)
    UBoxComponent Box05;
    default Box05.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box05.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh06)
    UBoxComponent Box06;
    default Box06.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box06.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh07)
    UBoxComponent Box07;
    default Box07.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box07.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh08)
    UBoxComponent Box08;
    default Box08.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box08.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh09)
    UBoxComponent Box09;
    default Box09.RelativeLocation = FVector(-200.f, -200.f, 200.f);
    default Box09.BoxExtent = FVector(200.f, 200.f, 200.f);

    UPROPERTY(DefaultComponent, Attach = Mesh01)
    UStaticMeshComponent Spike01;
    default Spike01.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike01.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh02)
    UStaticMeshComponent Spike02;
    default Spike02.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike02.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh03)
    UStaticMeshComponent Spike03;
    default Spike03.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike03.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh04)
    UStaticMeshComponent Spike04;
    default Spike04.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike04.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh05)
    UStaticMeshComponent Spike05;
    default Spike05.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike05.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh06)
    UStaticMeshComponent Spike06;
    default Spike06.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike06.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh07)
    UStaticMeshComponent Spike07;
    default Spike07.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike07.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh08)
    UStaticMeshComponent Spike08;
    default Spike08.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike08.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Mesh09)
    UStaticMeshComponent Spike09;
    default Spike09.RelativeLocation = FVector(-200.f, -200.f, -450.f);
    default Spike09.RelativeScale3D = FVector(0.25f, 0.25f, 0.75f);

    UPROPERTY(DefaultComponent, Attach = Root)
    USpotLightComponent Spotlight;
    default Spotlight.RelativeRotation = FRotator(-90., 0.f, 0.f);
    default Spotlight.CastShadows = false;
    default Spotlight.bVisible = false;

    UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

    TArray<UBoxComponent> BoxColliderArray;
    TArray<UStaticMeshComponent> SpikeArray;
    FVector SpikeLoweredLocation;
    FVector SpikeRaisedLocation;
    bool bShowSpikes;
    bool bShouldMoveSpikes;
    float LerpAlpha;
    int CurrentBoxOverlapping = -1;
    int CurrentBoxAnswer = -1;
    int SpikeToIgnore;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetActorTickEnabled(false);

		FillBoxColliderArray();
        FillSpikeArray();

        SpikeLoweredLocation = FVector(Spike01.RelativeLocation.X, Spike01.RelativeLocation.Y, -450.f);
        SpikeRaisedLocation = FVector(Spike01.RelativeLocation.X, Spike01.RelativeLocation.Y, -200.f);

        GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ActorGroundPounded");
    }

    UFUNCTION()
    void ActorGroundPounded(AHazePlayerCharacter Player)
    {
        CurrentBoxAnswer = CurrentBoxOverlapping;
        MoveSpotlight(CurrentBoxAnswer);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        CheckOverlaps();

        if (bShouldMoveSpikes)
        {
            if (bShowSpikes)
            {
                for (int i = 0; i < SpikeArray.Num(); i++)
                {
                    SpikeArray[i].SetRelativeLocation(FMath::VLerp(SpikeLoweredLocation, SpikeRaisedLocation, FVector(LerpAlpha, LerpAlpha, LerpAlpha)));
                }

                if (LerpAlpha < 1)
                {
                    LerpAlpha += ActorDeltaSeconds * 5.f;
                } else 
                {
                    bShouldMoveSpikes = false;
                }
            } else
            {
                for (int i = 0; i < SpikeArray.Num(); i++)
                {   
                    SpikeArray[i].SetRelativeLocation(FMath::VLerp(SpikeLoweredLocation, SpikeRaisedLocation, FVector(LerpAlpha, LerpAlpha, LerpAlpha)));
                }

                if (LerpAlpha > 0)
                {
                    LerpAlpha -= ActorDeltaSeconds * 5.f;
                } else 
                {
                    bShouldMoveSpikes = false;
                }
            }
        }
    }

    void FillBoxColliderArray()
    {
        BoxColliderArray.Add(Box01);
        BoxColliderArray.Add(Box02);
        BoxColliderArray.Add(Box03);
        BoxColliderArray.Add(Box04);
        BoxColliderArray.Add(Box05);
        BoxColliderArray.Add(Box06);
        BoxColliderArray.Add(Box07);
        BoxColliderArray.Add(Box08);
        BoxColliderArray.Add(Box09);
    }

    void FillSpikeArray()
    {
        SpikeArray.Add(Spike01);
        SpikeArray.Add(Spike02);
        SpikeArray.Add(Spike03);
        SpikeArray.Add(Spike04);
        SpikeArray.Add(Spike05);
        SpikeArray.Add(Spike06);
        SpikeArray.Add(Spike07);
        SpikeArray.Add(Spike08);
        SpikeArray.Add(Spike09);
    }

    void CheckOverlaps()
    {
        for (int i = 0; i < BoxColliderArray.Num(); i++)
        {
            TArray<AActor> OverlappingActors;
            BoxColliderArray[i].GetOverlappingActors(OverlappingActors);

            for (AActor Actor : OverlappingActors)
            {
                if (Cast<AHazePlayerCharacter>(Actor) != nullptr)
                {
                    CurrentBoxOverlapping = i;
                }
            }
        }
    }

    UFUNCTION()
    void MoveSpikes(bool bShouldBeLowered)
    {
        LerpAlpha = bShouldBeLowered ? 1.f : 0.f;
        bShowSpikes = !bShouldBeLowered;
        bShouldMoveSpikes = true;
    }

    void MoveSpotlight(int Index)
    {
        Spotlight.SetWorldLocation(BoxColliderArray[Index].GetWorldLocation());
        
        if (!Spotlight.IsVisible())
            Spotlight.SetVisibility(true);
    }

    void ResetAnswers()
    {
        CurrentBoxAnswer = -1;
        Spotlight.SetVisibility(false);
    }
}