class ULocomotionFeatureGardenSpaCaterpillar : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGardenSpaCaterpillar()
    {
        Tag = n"SpaCaterpillar";
    }

    UPROPERTY()
    FHazePlaySequenceData MH;

	UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlaySequenceData MayEnter;

	UPROPERTY()
    FHazePlaySequenceData CodyMassageMH;

	UPROPERTY()
    FHazePlaySequenceData MayMassageMH;

	UPROPERTY()
    FHazePlaySequenceData Exit;

};