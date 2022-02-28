class ULocomotionFeatureNailCatch: UHazeLocomotionFeatureBase
{
    default Tag = n"NailCatch";


	UPROPERTY(Category = "Catch")
    FHazePlayBlendSpaceData Catch;

	UPROPERTY(Category = "Catch")
    FHazePlaySequenceData CatchRight;
};