class ULocomotionFeatureWaterHoseStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";


    UPROPERTY(Category = "MH")
    FHazePlayRndSequenceData AimMH;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimBlendSpace;

    UPROPERTY(Category = "Shoot")
    FHazePlaySequenceData Shoot;
};