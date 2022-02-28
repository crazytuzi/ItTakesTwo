class ULocomotionFeaturePowerfulSong : UHazeLocomotionFeatureBase 
{
    ULocomotionFeaturePowerfulSong()
    {
        Tag = n"PowerfulSong";
    }

    UPROPERTY()
    FHazePlaySequenceData AimStart;

	UPROPERTY()
	FHazePlaySequenceData AimMH;

	UPROPERTY()
	FHazePlaySequenceData AimExit;

	UPROPERTY()
	UAimOffsetBlendSpace AimBlendSpace;
}