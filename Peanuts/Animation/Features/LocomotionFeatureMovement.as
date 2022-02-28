class ULocomotionFeatureMovement : UHazeLocomotionFeatureBase
{
   default Tag = n"Movement";
    

    UPROPERTY()
    FHazePlayRndSequenceData IdleAnimations;
    
    //Enables Idle gestures when player has been standing still without input
    UPROPERTY(Category = "IdleAnimations")
    bool UseIdleGestures = false;

	UPROPERTY(Category = "IdleAnimations")
    float IdleGestureTriggerTime = 10.0f;

	UPROPERTY(Category = "IdleAnimations")
    float BigGestureTriggerTime = 30.0f;

	UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData IdleGestures;

	UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData BigGestures;

    // Will be ignored if no Start animation is valid
    UPROPERTY()
    FHazePlaySequenceData StartAnimation;
    
    // Will be ignored if no Stop animation is valid
    UPROPERTY()
    FHazePlaySequenceData StopAnimation;

    UPROPERTY()
    bool useMovementBlendSpace;

    UPROPERTY()
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY()
    FHazePlayRndSequenceData Movement;

	// Transition animation from this MH into Advanced Movement MH, when SubABP switches
    UPROPERTY()
    FHazePlaySequenceData Transition;	
};