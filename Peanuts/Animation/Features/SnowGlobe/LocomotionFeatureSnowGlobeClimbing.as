class ULocomotionFeatureSnowGlobeClimbing : UHazeLocomotionFeatureBase
{
    default Tag = n"Climbing";

    UPROPERTY(Category = "Climbing")
    FHazePlaySequenceData GripEnter;

    UPROPERTY(Category = "Climbing")
    FHazePlaySequenceData GripMH;

	UPROPERTY(Category = "Climbing")
    FHazePlaySequenceData GripExit;

    //UPROPERTY(Category = "Climbing")
    //UBlendSpaceBase TurnIdleBlendSpace;
};