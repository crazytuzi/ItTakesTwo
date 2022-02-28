event void FPlayerOutOfBounds(AHazePlayerCharacter Player);

class ACurlingPlayerOutOfBounds : AHazeActor
{
	FPlayerOutOfBounds EventPlayerOutOfBounds; 

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		EventPlayerOutOfBounds.Broadcast(Player);
    }
}