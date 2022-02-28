import Cake.LevelSpecific.Hopscotch.RotatingPlatform;

class ARotatingPlatformManager : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent BoxCollision;

    UPROPERTY()
    TArray<ARotatingPlatform> PlatformArray;

    float CombinedInputAxis;
    float InputAxisMay;
    float InputAxisCody;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TArray<AActor> RotatingPlatforms;
        BoxCollision.GetOverlappingActors(RotatingPlatforms);

        for (AActor CurrentActor : RotatingPlatforms)
        {
            
            ARotatingPlatform Platform = Cast<ARotatingPlatform>(CurrentActor);

            if (Platform != nullptr)
            {
                PlatformArray.Add(Platform);
            }
        }
    }

    void ReceiveInputAxis(float InputAxis, AHazePlayerCharacter Player)
    {
        if (Player == Game::GetCody())
            InputAxisCody = InputAxis;
        
        else
            InputAxisMay = InputAxis;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        CombinedInputAxis = InputAxisCody + InputAxisMay;
        CombinedInputAxis = FMath::Clamp(CombinedInputAxis, 0.f, 1.f);

        for(ARotatingPlatform Platform : PlatformArray)
        {
            //Platform.CustomTimeDilation = CombinedInputAxis;
            Platform.CustomTimeDilation = FMath::FInterpTo(Platform.CustomTimeDilation, CombinedInputAxis, ActorDeltaSeconds, 3.0f);
        }
    }
}