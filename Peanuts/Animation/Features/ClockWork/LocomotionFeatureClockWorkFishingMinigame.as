class ULocomotionFeatureClockWorkFishingMinigame : UHazeLocomotionFeatureBase
{

    default Tag = n"FishingMinigame";

	UPROPERTY(Category= "Turning")
	FHazePlayBlendSpaceData Turning;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData Anticipation;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData AnticipationMh;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData FishingMh;

	UPROPERTY(Category = "Fishing")
    FHazePlayBlendSpaceData ReelingIn;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData HoldingCatch;

	UPROPERTY(Category = "Fishing")
    FHazePlaySequenceData ThrowCatch;

	// IK Reference pose for right hand on lever
	UPROPERTY(Category= "IK Ref")
	FHazePlaySequenceData TurningIKRef;

	UPROPERTY(Category = "IK Ref")
    FHazePlaySequenceData ReelingInIKRef;

}