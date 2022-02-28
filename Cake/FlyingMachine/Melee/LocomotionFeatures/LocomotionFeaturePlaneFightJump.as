class UHazeLocomotionFeaturePlaneFightJump : ULocomotionFeatureMeleeDefault
{
    default Tag = FeatureName::Jump;

    UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Jump;

    UPROPERTY(Category = "Animation")
    FHazePlaySequenceData Landing;

}