class UGardenSpaButterflyAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly)
    FHazePlayRndSequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData TakeOff;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData FlyMh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Land;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

    }

    

}