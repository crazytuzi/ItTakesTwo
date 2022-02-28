

class ULocomotionFeatureCraneCrank : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureCraneCrank()
    {
        Tag = n"CraneCrank";
    }

	// General movement

    // Additive MH animation
    UPROPERTY(Category = "Enter")
    FHazePlaySequenceData Enter;

	// Movement blendspce
	UPROPERTY(Category = "MH")
    FHazePlayBlendSpaceData MH;

	// Additive MH animation
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData Exit;

	

};