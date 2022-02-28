class ULocomotionFeatureSniperAimInAir : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSniperAimInAir()
    {
        Tag = FeatureName::AirMovement;
    }

    UPROPERTY(Category = "Locomotion InAir")
    FHazePlayBlendSpaceData InAir;

	// Played when shooting
    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData FinalShot;

	UPROPERTY(Category = "Fall Time")
	float FallTimeMultiply = 1;
};