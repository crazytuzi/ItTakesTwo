class ULocomotionFeatureSnowGlobeClimbingSwing : UHazeLocomotionFeatureBase
{
    default Tag = n"ClimbingSwing";

    UPROPERTY(Category = "ClimbingSwing")
    FHazePlaySequenceData SwingEnter;

    UPROPERTY(Category = "ClimbingSwing")
    FHazePlaySequenceData SwingMH;

	UPROPERTY(Category = "ClimbingSwing")
    FHazePlaySequenceData SwingExit;

    //UPROPERTY(Category = "Climbing")
    //UBlendSpaceBase TurnIdleBlendSpace;
};