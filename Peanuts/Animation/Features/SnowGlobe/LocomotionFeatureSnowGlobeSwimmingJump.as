class ULocomotionFeatureSnowGlobeSwimmingJump : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingJump";

    // Jump out of surface swimming
    UPROPERTY(Category = "SwimmingJump")
    FHazePlaySequenceData Jump;

};