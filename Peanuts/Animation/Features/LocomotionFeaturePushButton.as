class ULocomotionFeaturePushButton : UHazeLocomotionFeatureBase
{
    default Tag = n"PushButton";

	UPROPERTY(Category = "Hold Button")
    FHazePlaySequenceData StartPush;

	UPROPERTY(Category = "Hold Button")
    FHazePlaySequenceData HoldMh;

	UPROPERTY(Category = "Hold Button")
    FHazePlaySequenceData Release;


	UPROPERTY(Category = "Push Button")
    bool bUseSingleSequence;

	UPROPERTY(Category = "Push Button")
    FHazePlaySequenceData PushButton;

}