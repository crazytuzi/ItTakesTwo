class ULocomotionFeatureSkyDive : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSkyDive()
    {
        Tag = n"SkyDive";
    }

	UPROPERTY(Category = "SkyDive")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "SkyDive")
    FHazePlayBlendSpaceData SkyDive;
};