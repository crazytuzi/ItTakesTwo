class ULocomotionFeatureSnowGlobeSwimmingDash : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingDashEnter";

    // Dash animation to play when dashing under water
    UPROPERTY(Category = "SwimmingDash")
    FHazePlaySequenceData Dash;

	UPROPERTY(Category = "SwimmingDash")
    FHazePlaySequenceData DashToFastSwim;

    // Exit to swimming mh
    UPROPERTY(Category = "SwimmingDash")
    FHazePlaySequenceData DashExitToMh;


};