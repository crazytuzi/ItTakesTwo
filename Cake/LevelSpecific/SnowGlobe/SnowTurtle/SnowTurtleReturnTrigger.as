import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class ASnowTurtleReturnTrigger : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;
	default TriggerComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	ASnowTurtleBaby SnowTurtle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl())
			TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		SnowTurtle = Cast<ASnowTurtleBaby>(OtherActor);

		if (SnowTurtle == nullptr)
			return;
		
		NetActivateTurtleNest(SnowTurtle);
    }

	UFUNCTION(NetFunction)
	void NetActivateTurtleNest(ASnowTurtleBaby InSnowTurtle)
	{
		InSnowTurtle.ActivateTurtleToNest();
	}
}