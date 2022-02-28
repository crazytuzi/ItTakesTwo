class ULocomotionFeatureCymbalAirAim: UHazeLocomotionFeatureBase
{
    default Tag = n"CymbalAirAim";


    UPROPERTY()
    FHazePlayBlendSpaceData AimBs;

    UPROPERTY()
    FHazePlaySequenceData Throw;

	UPROPERTY()
    FHazePlaySequenceData Equip;

	UPROPERTY()
    FHazePlaySequenceData Unequip;

};