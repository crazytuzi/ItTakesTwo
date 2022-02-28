class ULocomotionFeatureSnowGlobeHarpoon : UHazeLocomotionFeatureBase
{

    default Tag = n"MagnetHarpoon";

    UPROPERTY(Category = "Harpoon")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "Harpoon")
    FHazePlaySequenceData AdditiveMh;

	UPROPERTY(Category = "Harpoon")
    FHazePlaySequenceData Fire;

	UPROPERTY(Category = "Harpoon")
    FHazePlaySequenceData Release;


	UPROPERTY(Category = "Harpoon")
    FHazePlaySequenceData IKRef;

}