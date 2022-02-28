import Cake.LevelSpecific.Hopscotch.BallFallValve;
class ATimeDimensionFountain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FountainMesh;

	UPROPERTY(DefaultComponent, Attach = FountainMesh)
	UNiagaraComponent WaterSplashFX;
	default WaterSplashFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = FountainMesh)
	USphereComponent SphereCollision;

	UPROPERTY()
	ABallFallValve Valve;

	bool bFountainActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Valve.ValveActivatedEvent.AddUFunction(this, n"ValveActivated");
		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		//ActivateWaterFX();
	}

	UFUNCTION()
	void ActivateWaterFX()
	{
		WaterSplashFX.Activate();
		bFountainActive = true;
	}

	UFUNCTION()
	void ValveActivated(EValveColor ValveColor)
	{
		ActivateWaterFX();
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
       if (!bFountainActive)
	   	return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.AddImpulse(FVector(0.f, 0.f, 8000.f));
		}
    }
}