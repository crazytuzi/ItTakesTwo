class ULocomotionFeatureTV: UHazeLocomotionFeatureBase
{
    ULocomotionFeatureTV()
    {
        Tag = n"TV";
    }
	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Right;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Left;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData MH;
};