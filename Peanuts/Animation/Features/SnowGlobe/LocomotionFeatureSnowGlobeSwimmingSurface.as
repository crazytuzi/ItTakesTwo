class ULocomotionFeatureSnowGlobeSwimmingSurface : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingSurface";

	// Swimming fwd 1D Blendspace
    UPROPERTY(Category = "SwimmingSurface")
    FHazePlayBlendSpaceData SwimForwards;

	// Dive into the underwater swimset
    UPROPERTY(Category = "SwimmingSurface")
    FHazePlaySequenceData Dive;

	// Exiting from the dive to the Mh
    UPROPERTY(Category = "SwimmingSurface")
    FHazePlaySequenceData DiveExitToMh;

};