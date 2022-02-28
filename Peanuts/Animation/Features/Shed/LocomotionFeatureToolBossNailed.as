class ULocomotionFeatureToolBossNailed: UHazeLocomotionFeatureBase
{
    default Tag = n"ToolBossNailed";


    UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlayBlendSpaceData Struggle;

	UPROPERTY()
    FHazePlaySequenceData Exit;

};