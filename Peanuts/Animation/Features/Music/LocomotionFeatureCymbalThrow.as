class ULocomotionFeatureCymbalThrow : UHazeLocomotionFeatureBase
{
    default Tag = n"CymbalThrow";

    UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Land;

};