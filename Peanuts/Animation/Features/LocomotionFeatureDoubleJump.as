class ULocomotionFeatureDoubleJump : UHazeLocomotionFeatureBase
{

    default Tag = n"DoubleJump";
    

    UPROPERTY()
    FHazePlaySequenceData DoubleJump;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
	
};