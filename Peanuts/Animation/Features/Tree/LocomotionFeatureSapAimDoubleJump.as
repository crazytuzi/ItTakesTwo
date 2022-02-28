class ULocomotionFeatureSapAimDoubleJump : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSapAimDoubleJump()
    {
        Tag = n"DoubleJump";
    }

    UPROPERTY()
    FHazePlayBlendSpaceData DoubleJump;

    UPROPERTY()
    FHazePlayBlendSpaceData AimSpace;
};