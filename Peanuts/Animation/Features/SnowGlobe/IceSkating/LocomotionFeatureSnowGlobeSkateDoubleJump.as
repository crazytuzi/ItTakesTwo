class ULocomotionFeatureSnowGlobeSkateDoubleJump : UHazeLocomotionFeatureBase
{
	default Tag = n"SkateDoubleJump";

    UPROPERTY(Category = "Jump")
    FHazePlayRndSequenceData Jump;

    UPROPERTY(Category = "Jump")
    FHazePlayRndSequenceData JumpToGlide;
};