class ULocomotionFeatureSlingShot : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSlingShot()
    {
        Tag = n"SlingShot";
    }
	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Load;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Struggle;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData WalkStart;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Walk;

	UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Slide;
};