class AHelltowerAchievementBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr) 
			Online::UnlockAchievement(Player, n"Helltower");
    }
}