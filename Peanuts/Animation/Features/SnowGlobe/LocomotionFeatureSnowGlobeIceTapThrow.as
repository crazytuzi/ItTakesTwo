class ULocomotionFeatureSnowGlobeIceTapThrow : UHazeLocomotionFeatureBase
{

    default Tag = n"IceTapThrow";

    
    
    // General movement

    // Additive MH animation
    UPROPERTY(Category = "Enter")
    FHazePlaySequenceData Enter;

	// Additive MH animation
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData Exit;

	// Additive MH animation
    UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Throw;

	// Movement blendspce
	UPROPERTY(Category = "MH")
    FHazePlayBlendSpaceData MH;

	

}