
class ULocomotionFeatureRecordCrusherPlayerGhost : UHazeLocomotionFeatureBase
{
    default Tag = n"RecordCrusherPlayerGhost";

    UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData ReverseMovementBlendSpace;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlaySequenceData IdleAnimation;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlaySequenceData ReverseIdleAnimation;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlaySequenceData DashAnimation;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlaySequenceData ReverseDashAnimation;
};