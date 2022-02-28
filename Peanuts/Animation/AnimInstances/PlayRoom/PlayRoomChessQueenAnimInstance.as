class UPlayRoomChessQueenAnimInstance : UHazeCharacterAnimInstance
{

 	UPROPERTY()
    FHazePlaySequenceData Enter;

 	UPROPERTY()
    FHazePlaySequenceData IdleMH;

	UPROPERTY()
    FHazePlaySequenceData MoveStart;

	UPROPERTY()
	FHazePlaySequenceData MoveMH;

	UPROPERTY()
	FHazePlaySequenceData MoveExit;

	UPROPERTY()
    FHazePlaySequenceData Summon;

	UPROPERTY()
    FHazePlaySequenceData Death;

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