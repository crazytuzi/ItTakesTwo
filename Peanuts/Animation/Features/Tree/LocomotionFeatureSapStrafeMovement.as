class ULocomotionFeatureSapStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";
    
    UPROPERTY(Category = "Idle")
    FHazePlayRndSequenceData IdleAnimations;
    
    // Starting to move from idle
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData StartBlendSpace;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData TurnInPlaceBlendSpace;

    // Stopping movement (standing still)
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData StopBlendSpace;

    // Played when first entering this locomotion state (started aiming)
    UPROPERTY(Category = "Transitions")
    FHazePlaySequenceData EnterAnimation;

    // Played when exiting this locomotion state (stopped aiming)
    UPROPERTY(Category = "Transitions")
    FHazePlaySequenceData ExitAnimation;

    // Played when exiting this locomotion state (stopped aiming)
    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimBlendSpace;

    // Played when shooting
    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData ShootStart;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData ShootMh;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData ShootExit;
};