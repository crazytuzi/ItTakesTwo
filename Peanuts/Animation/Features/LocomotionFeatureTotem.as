

class ULocomotionTotemBodyAnimationFeature : UHazeLocomotionFeatureBase
{
	ULocomotionTotemBodyAnimationFeature()
    {
        Tag = n"Totem";
    }

    UPROPERTY()
    FHazePlaySequenceData LaunchHead; 
};

class ULocomotionTotemHeadAnimationFeature : UHazeLocomotionFeatureBase
{
	ULocomotionTotemHeadAnimationFeature()
    {
        Tag = n"Totem";
    }

	UPROPERTY(Category = "Perch|Totem")
    FBurstForceFeaturePart Launched;
};

class ULocomotionTotemFeature : UHazeLocomotionFeatureBase
{
	ULocomotionTotemFeature()
    {
        Tag = n"Totem";
    }

	UPROPERTY()
	FHazePlaySequenceData WaitingResponse;

	UPROPERTY()
	FHazePlaySequenceData TravelTo;

	UPROPERTY()
	FHazePlaySequenceData Release;

	UPROPERTY()
	FHazePlaySequenceData JumpOff;
};

