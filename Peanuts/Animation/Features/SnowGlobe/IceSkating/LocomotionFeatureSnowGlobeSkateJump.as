class ULocomotionFeatureSnowGlobeSkateJump : UHazeLocomotionFeatureBase
{
	default Tag = n"SkateJump";

	UPROPERTY(Category = "Jump")
	FHazePlayBlendSpaceData Charge;

    UPROPERTY(Category = "Jump")
    FHazePlayRndSequenceData JumpStart;

	UPROPERTY(Category = "Jump")
    FHazePlayRndSequenceData JumpStartVarB;

    UPROPERTY(Category = "Jump")
    FHazePlaySequenceData JumpToAirGlide;

	UPROPERTY(Category = "Swimming")
	FHazePlaySequenceData SwimmingDive;
};