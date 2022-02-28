class ULocomotionFeatureJumpTo : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureJumpTo()
    {
        Tag = n"JumpTo";
    }

    // Animation to play when starting the JumpTo
    UPROPERTY(Category = "Jump To")
    FHazePlaySequenceData JumpEnter;

    // Animation to play when the enter-animation is finished but we havent yet reached the target
    UPROPERTY(Category = "Jump To")
    FHazePlaySequenceData JumpFalling;
};