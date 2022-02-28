class ULocomotionFeatureDandelionFlight : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureDandelionFlight()
    {
        Tag = n"Dandelion";
    }

	// Movement BlendSpace
    UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Launch;

    // Movement BlendSpace
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

	
};