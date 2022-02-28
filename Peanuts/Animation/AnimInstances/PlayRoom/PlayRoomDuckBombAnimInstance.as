class UPlayRoomDuckBombAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Emerge;

    UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData FloatMH;

	UPROPERTY(BlueprintReadOnly)
    FHazePlayBlendSpaceData HeadPulseBS;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData DynamitePulse;

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Explode;


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