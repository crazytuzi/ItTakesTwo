class ULocomotionFeatureLongJump : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureLongJump()
    {
        Tag = n"LongJump";
    }

	UPROPERTY(Category = "LongJump")
	FHazePlaySequenceData LongJump;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;

}