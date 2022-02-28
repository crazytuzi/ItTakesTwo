enum EHazeKissProgressStateAnimations
{
	Blendspace,
	ToHugTransition,
}


class ULocomotionFeatureGrandFinaleKiss: UHazeLocomotionFeatureBase
{
    default Tag = n"GrandFinaleKiss";


	UPROPERTY()
    FHazePlaySequenceData SmoochOneshot;

	UPROPERTY()
    FHazePlayBlendSpaceData AdditiveMh;

	UPROPERTY()
	FHazePlayRndSequenceData IdleFace;

	UPROPERTY()
	FHazePlayRndSequenceData IdleFaceAdditive;

	UPROPERTY()
	FHazePlayRndSequenceData ProgressFace;

    UPROPERTY()
    FHazePlayBlendSpaceData ProgressBS;

    UPROPERTY()
    FHazePlaySequenceData ToHug;
	
};