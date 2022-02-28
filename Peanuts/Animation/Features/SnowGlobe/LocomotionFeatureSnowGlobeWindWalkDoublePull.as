class ULocomotionFeatureSnowGlobeWindWalkDoublePull : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSnowGlobeWindWalkDoublePull()
    {
        Tag = n"DoublePull";
    }


	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData MhNotConnected;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData EnterMh;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData ExitMh;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData Struggle;

	// ! Important: This should not have loop enabled !
	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData Walk;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData FallingBackEnter;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData Falling;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData FallingBackExit;
	
}