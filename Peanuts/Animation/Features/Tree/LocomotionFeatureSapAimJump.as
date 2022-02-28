class ULocomotionFeatureSapAimJump : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSapAimJump()
    {
        Tag = FeatureName::Jump;
    }

    // The animation when you dash from velocity
    UPROPERTY(Category = "Locomotion Jump")
    FHazePlayBlendSpaceData JumpStart;
	
	UPROPERTY(Category = "Locomotion Jump")
	FHazePlayBlendSpaceData AimSpace;

    //VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
};