class ULocomotionFeatureBowlingBallHanging : UHazeLocomotionFeatureBase
{

    default Tag = n"WreckingBallHanging";

	UPROPERTY(Category = "BowlingBallHanging")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "BowlingBallHanging")
    FHazePlayBlendSpaceData Hanging;

	UPROPERTY(Category = "BowlingBallHanging")
    FHazePlaySequenceData HitDoor;
};