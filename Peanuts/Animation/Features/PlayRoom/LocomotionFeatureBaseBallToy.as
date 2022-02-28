class ULocomotionFeatureBaseBallToy : UHazeLocomotionFeatureBase
{

    default Tag = n"BaseBallToy";

	UPROPERTY(Category = "BaseBallToy")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "BaseBallToy")
    FHazePlayBlendSpaceData Swing;

	UPROPERTY(Category = "BaseBallToy")
    FHazePlaySequenceData Exit;
};