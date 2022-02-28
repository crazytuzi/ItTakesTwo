class ULocomotionFeatureMicrophoneSnake : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureMicrophoneSnake()
    {
        Tag = n"MicrophoneSnake";
    }



    UPROPERTY()
    FHazePlaySequenceData Resting;

    UPROPERTY()
    FHazePlayRndSequenceData Awake;

	UPROPERTY()
	FHazePlayBlendSpaceData HypnotizedBlendSpace;

	UPROPERTY()
    FHazePlaySequenceData HypnosisExit;

    UPROPERTY()
    FHazePlaySequenceData Attacking;

	UPROPERTY()
    FHazePlaySequenceData Bite;

	UPROPERTY()
    FHazePlaySequenceData Swallow;

	UPROPERTY()
    FHazePlaySequenceData Flinch;

	UPROPERTY()
    FHazePlaySequenceData Death;

}
