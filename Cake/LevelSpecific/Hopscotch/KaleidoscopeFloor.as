class AKaleidoscopeFloor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent RedRoot;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent BlueRoot;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent YellowRoot;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor1;
    default RedFloor1.RelativeRotation = FRotator(0.f, 0.f, 0.f);
    default RedFloor1.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor1;
    default BlueFloor1.RelativeRotation = FRotator(0.f, 0.f, 0.f);
    default BlueFloor1.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor1;
    default YellowFloor1.RelativeRotation = FRotator(0.f, 0.f, 0.f);
    default YellowFloor1.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor2;
    default RedFloor2.RelativeRotation = FRotator(0.f, 60.f, 0.f);
    default RedFloor2.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor2;
    default BlueFloor2.RelativeRotation = FRotator(0.f, 60.f, 0.f);
    default BlueFloor2.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor2;
    default YellowFloor2.RelativeRotation = FRotator(0.f, 60.f, 0.f);
    default YellowFloor2.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor3;
    default RedFloor3.RelativeRotation = FRotator(0.f, 120.f, 0.f);
    default RedFloor3.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor3;
    default BlueFloor3.RelativeRotation = FRotator(0.f, 120.f, 0.f);
    default BlueFloor3.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor3;
    default YellowFloor3.RelativeRotation = FRotator(0.f, 120.f, 0.f);
    default YellowFloor3.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor4;
    default RedFloor4.RelativeRotation = FRotator(0.f, 180.f, 0.f);
    default RedFloor4.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor4;
    default BlueFloor4.RelativeRotation = FRotator(0.f, 180.f, 0.f);
    default BlueFloor4.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor4;
    default YellowFloor4.RelativeRotation = FRotator(0.f, 180.f, 0.f);
    default YellowFloor4.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor5;
    default RedFloor5.RelativeRotation = FRotator(0.f, 240.f, 0.f);
    default RedFloor5.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor5;
    default BlueFloor5.RelativeRotation = FRotator(0.f, 240.f, 0.f);
    default BlueFloor5.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor5;
    default YellowFloor5.RelativeRotation = FRotator(0.f, 240.f, 0.f);
    default YellowFloor5.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = RedRoot)
    UStaticMeshComponent RedFloor6;
    default RedFloor6.RelativeRotation = FRotator(0.f, 300.f, 0.f);
    default RedFloor6.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = BlueRoot)
    UStaticMeshComponent BlueFloor6;
    default BlueFloor6.RelativeRotation = FRotator(0.f, 300.f, 0.f);
    default BlueFloor6.bCastDynamicShadow = false;

    UPROPERTY(DefaultComponent, Attach = YellowRoot)
    UStaticMeshComponent YellowFloor6;
    default YellowFloor6.RelativeRotation = FRotator(0.f, 300.f, 0.f);
    default YellowFloor6.bCastDynamicShadow = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {

    }

    UFUNCTION()
    void UpdateKaleidoscopeRotation(TArray<FRotator> NewRotation)
    {
        RedRoot.SetRelativeRotation(NewRotation[0]);
        BlueRoot.SetRelativeRotation(NewRotation[1]);
        YellowRoot.SetRelativeRotation(NewRotation[2]);
    }
}