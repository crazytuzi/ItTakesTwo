class ULocomotionFeatureCannonFly : UHazeLocomotionFeatureBase
{
    default Tag = n"CannonFly";

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData CannonFlyMH;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData CannonFlyEnter;
};