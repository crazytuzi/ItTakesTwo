class ULocomotionFeatureSnowGlobeSwimmingDive : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingDive";

	// Dive into water from land. This will blend out to breach dive once finished.
    UPROPERTY(Category = "SwimmingDive")
    FHazePlaySequenceData Dive;

	UPROPERTY(Category = "SwimmingDive")
    FHazePlaySequenceData DiveMh;

};