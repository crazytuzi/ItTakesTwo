class ULocomotionFeatureSnowGlobeSkateBoost : UHazeLocomotionFeatureBase
{
     default Tag = n"SkateBoost";

    /*
	// The animation when you initiate cruise with the left foot from low velocity
    UPROPERTY(Category = "Left Foot")
    FHazePlaySequenceData LeftBoostSlow;

    // The animation when you initiate cruise with the left foot from high velocity
    UPROPERTY(Category = "Left Foot")
    FHazePlaySequenceData LeftBoostFast;

	// The animation when you initiate cruise with the right foot from low velocity
    UPROPERTY(Category = "Right Foot")
    FHazePlaySequenceData RightBoostSlow;

    // The animation when you initiate cruise with the right foot from high velocity
    UPROPERTY(Category = "Right Foot")
    FHazePlaySequenceData RightBoostFast;*/

	UPROPERTY(Category = "SingleBoost")
	FHazePlayBlendSpaceData Boost;

	UPROPERTY(Category = "ButtonMashing")
	FHazePlayBlendSpaceData BoostMh;

	UPROPERTY(Category = "ButtonMashing")
	FHazePlaySequenceData BoostExit;

};