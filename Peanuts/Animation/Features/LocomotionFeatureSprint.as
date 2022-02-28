class ULocomotionFeatureSprint : UHazeLocomotionFeatureBase
{

    default Tag = n"Sprint";

	UPROPERTY()
    FHazePlaySequenceData DashStart;

    UPROPERTY()
    FHazePlaySequenceData SprintFromLanding;

	UPROPERTY()
    FHazePlayBlendSpaceData Sprint;

    //UPROPERTY()
    //FHazePlaySequenceData Sprint;
};