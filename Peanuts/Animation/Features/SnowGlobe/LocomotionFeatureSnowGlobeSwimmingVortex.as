class ULocomotionFeatureSnowGlobeSwimmingVortex : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingVortex";

	UPROPERTY(Category = "Enter")
    FHazePlaySequenceData BreachEnter;

    UPROPERTY(Category = "SwimmingVortex")
    FHazePlayBlendSpaceData SwimmingVortex;

	UPROPERTY(Category = "SwimmingVortexUp")
    FHazePlaySequenceData SwimUpStart;

	UPROPERTY(Category = "SwimmingVortexUp")
    FHazePlaySequenceData SwimUp;

	UPROPERTY(Category = "SwimmingVortexUp")
    FHazePlaySequenceData SwimUpStop;

	UPROPERTY(Category = "SwimmingVortexDown")
    FHazePlaySequenceData SwimDownStart;

	UPROPERTY(Category = "SwimmingVortexDown")
    FHazePlaySequenceData SwimDown;

	UPROPERTY(Category = "SwimmingVortexDown")
    FHazePlaySequenceData SwimDownStop;

	UPROPERTY(Category = "Dash")
    FHazePlaySequenceData DashAnticipation;

	UPROPERTY(Category = "Dash")
    FHazePlaySequenceData Dash;

	UPROPERTY(Category = "Dash")
    FHazePlaySequenceData DashMH;

};