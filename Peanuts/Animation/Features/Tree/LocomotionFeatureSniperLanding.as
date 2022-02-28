class ULocomotionFeatureSniperLanding : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSniperLanding()
    {
        Tag = FeatureName::Landing;
    }

    UPROPERTY(Category = "Locomotion Landing")
    FHazePlayBlendSpaceData Land;

    UPROPERTY(Category = "Locomotion Landing")
    FHazePlaySequenceData LandAdd;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData FinalShot;

};