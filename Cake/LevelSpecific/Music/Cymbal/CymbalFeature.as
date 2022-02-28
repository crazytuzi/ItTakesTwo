class ULocomotionFeatureCymbal : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureCymbal()
    {
        Tag = n"Cymbal";
    }

    UPROPERTY(Category = "Aim")
    FHazePlaySequenceData AimStart;

	UPROPERTY(Category = "Aim")
	FHazePlaySequenceData AimMH;

	UPROPERTY(Category = "Aim")
	FHazePlaySequenceData AimExit;

	UPROPERTY(Category = "Aim")
	UAimOffsetBlendSpace AimBlendSpace;

	UPROPERTY(Category = "Shield")
	FHazePlaySequenceData ShieldEnter;

	UPROPERTY(Category = "Shield")
	FHazePlaySequenceData ShieldMH;

	UPROPERTY(Category = "Shield")
	FHazePlaySequenceData ShieldExit;

	UPROPERTY(Category = "Shield")
	UAimOffsetBlendSpace ShieldBlendSpace;

	UPROPERTY(Category = "Shield")
	FHazePlaySequenceData ShieldBash;

	UPROPERTY(Category = "Shield")
	FHazePlaySequenceData ShieldImpact;

	UPROPERTY(Category = "Surf")
	FHazePlaySequenceData SurfEnter;

	UPROPERTY(Category = "Surf")
	UBlendSpace SurfBS;

	UPROPERTY(Category = "Surf")
	FHazePlaySequenceData SurfExit;
}