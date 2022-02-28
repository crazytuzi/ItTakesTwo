import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class ABeanstalkLeafBlockerVolume : AVolume
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
		BrushComponent.OnComponentEndOverlap.AddUFunction(this, n"BrushEndOverlap");
	}
	
	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		ABeanstalk Beanstalk = Cast<ABeanstalk>(OtherActor);

		if(Beanstalk == nullptr || (Beanstalk != nullptr && !Beanstalk.HasControl()))
			return;

		Beanstalk.BlockLeafPair();
	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		ABeanstalk Beanstalk = Cast<ABeanstalk>(OtherActor);
		
		if(Beanstalk == nullptr || (Beanstalk != nullptr && !Beanstalk.HasControl()))
			return;

		Beanstalk.UnblockLeafPair();
	}
}
