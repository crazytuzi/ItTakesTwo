class ULocomotionFeatureSapAimInAir : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSapAimInAir()
    {
        Tag = FeatureName::AirMovement;
    }

    UPROPERTY(Category = "Locomotion InAir")
    FHazePlayBlendSpaceData InAir;

	UPROPERTY(Category = "Locomotion InAir")
    FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(Category = "Fall Time")
	float FallTimeMultiply = 1;
};