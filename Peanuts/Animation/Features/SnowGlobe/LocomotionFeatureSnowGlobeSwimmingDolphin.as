class ULocomotionFeatureSnowGlobeSwimmingDolphin : UHazeLocomotionFeatureBase
{
    default Tag = n"SwimmingFast";

	// Dolphin Swim
    UPROPERTY(Category = "DolphinSwim")
    FHazePlaySequenceData DolphinSwimEnter;

    // Dolphin Swim
    UPROPERTY(Category = "DolphinSwim")
    FHazePlayBlendSpaceData DolphinSwim;

    // Stop animation back into the normal swim state
    UPROPERTY(Category = "DolphinSwim")
    FHazePlaySequenceData Exit;

	// Stop animation back into the normal swim state
    UPROPERTY(Category = "DolphinSwim")
    FHazePlaySequenceData ExitToMh;

    // Dolphin Boost
    UPROPERTY(Category = "DolphinSwim")
    FHazePlaySequenceData DolphinSwimBoost;
    
};