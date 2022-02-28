class ULocomotionFeatureTurnAround : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureTurnAround()
    {
        Tag = FeatureName::TurnAround;
    }

	// If this is true, blendspaces are used for going into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	
	bool UseBlendspacesToMovement = false;

    UPROPERTY(Category = "180")
    FHazePlaySequenceData TurnL;

	UPROPERTY(Category = "180")
    FHazePlaySequenceData TurnR;

	// This only plays if Use Blendspaces to Movement is true
	UPROPERTY(Category = "180")
    FHazePlayBlendSpaceData TurnLBS;

	// This only plays if Use Blendspaces to Movement is true
    UPROPERTY(Category = "180")
    FHazePlayBlendSpaceData TurnRBS;

};