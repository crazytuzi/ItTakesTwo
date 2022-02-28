class ULocomotionFeatureGardenSpaCaterpillarSmall : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGardenSpaCaterpillarSmall()
    {
        Tag = n"SpaCaterpillarSmall";
    }

    UPROPERTY()
    FHazePlaySequenceData MH;

	UPROPERTY()
    FHazePlaySequenceData MHMirror;

	UPROPERTY()
    FHazePlaySequenceData EnterCody;

	UPROPERTY()
    FHazePlaySequenceData EnterCodyMirror;

	UPROPERTY()
    FHazePlaySequenceData EnterMay;

	UPROPERTY()
    FHazePlaySequenceData EnterMayMirror;

	UPROPERTY()
    FHazePlaySequenceData MassageMHCody;

	UPROPERTY()
    FHazePlaySequenceData MassageMHCodyMirror;

	UPROPERTY()
    FHazePlaySequenceData MassageMHMay;

	UPROPERTY()
    FHazePlaySequenceData MassageMHMayMirror;

	UPROPERTY()
    FHazePlaySequenceData ExitCody;

	UPROPERTY()
    FHazePlaySequenceData ExitCodyMirror;

	UPROPERTY()
    FHazePlaySequenceData ExitMay;

	UPROPERTY()
    FHazePlaySequenceData ExitMayMirror;

};