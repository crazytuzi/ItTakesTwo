class ULocomotionFeatureSnowGlobeSkidding : UHazeLocomotionFeatureBase
{
	default Tag = n"Skidding";

	UPROPERTY(Category = "Skidding")
	FHazePlayBlendSpaceData Movement;

    UPROPERTY(Category = "Skidding")
    FHazePlaySequenceData BoostLeft;

    UPROPERTY(Category = "Skidding")
    FHazePlaySequenceData BoostRight;
};