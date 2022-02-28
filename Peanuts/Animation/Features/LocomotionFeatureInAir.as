class ULocomotionFeatureInAir : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureInAir()
    {
        Tag = FeatureName::AirMovement;
    }

    UPROPERTY(Category = "Locomotion InAir")
    FHazePlayBlendSpaceData InAir;

	UPROPERTY(Category = "NailThrowing")
    FHazePlayBlendSpaceData InAirNail;

	UPROPERTY(Category = "NailThrowing")
    FHazePlaySequenceData InAirNailEquip;

	UPROPERTY(Category = "Fall Time")
	float FallTimeMultiply = 1;
};