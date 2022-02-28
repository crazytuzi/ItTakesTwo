class UGardenSpaAcupunctureAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData MayMh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData CodyMh;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Exit;


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