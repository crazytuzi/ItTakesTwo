class AFidgetSpinnerFastBoostVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BlowFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AirReleaseAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnBoostAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxBeginOverlap");
		HazeAkComp.HazePostEvent(AirReleaseAudioEvent);
	}
	
	UFUNCTION()
	void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		Player.SetCapabilityActionState(n"FidgetBoostFast", EHazeActionState::Active);
		HazeAkComp.HazePostEvent(OnBoostAudioEvent);
	}
}
