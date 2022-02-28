class AMicrophoneChaseNoStickInputVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		Box.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			if (Player.HasControl())
			{
				Player.BlockCapabilities(CapabilityTags::StickInput, this);
				Player.BlockCapabilities(n"SkyDive", this);
			}
	}

	UFUNCTION()
	void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			if (Player.HasControl())
			{
				Player.UnblockCapabilities(CapabilityTags::StickInput, this);
				Player.UnblockCapabilities(n"SkyDive", this);
			}
	}
}