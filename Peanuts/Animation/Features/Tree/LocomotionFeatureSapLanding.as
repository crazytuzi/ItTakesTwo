class ULocomotionFeatureSapLanding : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSapLanding()
    {
        Tag = FeatureName::Landing;
    }

    UPROPERTY(Category = "Locomotion Landing")
    FHazePlayBlendSpaceData Land;

    UPROPERTY(Category = "Locomotion Landing")
    FHazePlayBlendSpaceData AimSpace;
};