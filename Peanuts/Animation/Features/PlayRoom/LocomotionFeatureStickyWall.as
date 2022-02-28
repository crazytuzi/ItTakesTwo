class ULocomotionFeatureStickyWall : UHazeLocomotionFeatureBase
{
    default Tag = n"StickyWall";

	UPROPERTY(Category = "StickyWall")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "StickyWall")
    FHazePlayBlendSpaceData Struggle;

	UPROPERTY(Category = "StickyWall")
    FHazePlaySequenceData Exit;
};