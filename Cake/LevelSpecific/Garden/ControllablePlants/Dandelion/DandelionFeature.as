class ULocomotionFeatureDandelion : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureDandelion()
    {
        Tag = n"Dandelion";
    }

	UPROPERTY()
	FHazePlaySequenceData DandelionLaunch;

	UPROPERTY()
	FHazePlayBlendSpaceData DandelionBS;
}