class ULocomotionFeatureSniperStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";
    
    UPROPERTY(Category = "Idle")
    FHazePlaySequenceData IdleAnimations;
    
    // Starting to move from idle
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData StartBlendSpace;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

    // Stopping movement (standing still)
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData StopBlendSpace;

    UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Shuffle;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData ShuffleAdditive;

    // Played when exiting this locomotion state (stopped aiming)
    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData MhToAimBlendSpace;

    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimToMhBlendSpace;

    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimBlendSpace;

    // Played when shooting
    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData FinalShot;

};