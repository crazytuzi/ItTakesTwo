class ULocomotionFeaturePowerfulSongStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";
    
    UPROPERTY(Category = "Idle")
    FHazePlaySequenceData IdleAnimations;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Shuffle;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData ShuffleAdditive;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;


};