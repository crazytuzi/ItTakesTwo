class UPlayRoomGoldBergPenguinsAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(Category = "GoldBergPenguins")
    FHazePlayRndSequenceData Mh;

	UPROPERTY(Category = "GoldBergPenguins")
    FHazePlaySequenceData Escape1;

	UPROPERTY(Category = "GoldBergPenguins")
    FHazePlaySequenceData Escape2;

	UPROPERTY(Category = "GoldBergPenguins")
    FHazePlaySequenceData Push;

	UPROPERTY(Category = "GoldBergPenguins")
    FHazePlaySequenceData Fall;

	UPROPERTY(Category = "GoldBergPenguins")
    FHazePlaySequenceData FallSwim;


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