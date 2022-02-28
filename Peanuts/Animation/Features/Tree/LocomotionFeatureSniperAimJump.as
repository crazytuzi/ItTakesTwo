class ULocomotionFeatureSniperAimJump : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSniperAimJump()
    {
        Tag = FeatureName::Jump;
    }

    // The animation when you dash from velocity
    UPROPERTY(Category = "Locomotion Jump")
    FHazePlayBlendSpaceData JumpStart;

	// Played when shooting
    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData FinalShot;

    //VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
};