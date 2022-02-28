class ULocomotionFeatureCymbalCatch : UHazeLocomotionFeatureBase
{
    default Tag = n"CymbalCatch";

    UPROPERTY(Category = "Catch")
    FHazePlaySequenceData Catch;

	UPROPERTY(Category = "Catch")
    FHazePlaySequenceData Land;

};