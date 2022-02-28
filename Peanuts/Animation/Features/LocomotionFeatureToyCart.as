class ULocomotionFeatureToyCart : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureToyCart()
    {
        Tag = FeatureName::ToyCart;
    }
	//TimerWindows
	UPROPERTY(Category = "InputThresholds")
	float FastThreshold = 0.1f;

	UPROPERTY(Category = "InputThresholds")
	float MediumThreshold = 0.5f;

	UPROPERTY(Category = "InputThresholds")
	float SlowThreshold = 1.5f;

	//MH
	UPROPERTY(Category = "MH, Enter, Exit")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "MH, Enter, Exit")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "MH, Enter, Exit")
    FHazePlaySequenceData Exit;

	UPROPERTY(Category = "Loops")
    FHazePlaySequenceData Slow;

	UPROPERTY(Category = "Loops")
    FHazePlaySequenceData Medium;

	UPROPERTY(Category = "Loops")
    FHazePlaySequenceData Fast;

	UPROPERTY(Category = "Transitions")
    FHazePlaySequenceData Slow2Medium;

	UPROPERTY(Category = "Transitions")
    FHazePlaySequenceData Medium2Fast;

	UPROPERTY(Category = "Interrupts")
    FHazePlaySequenceData SlowInterrupt;

	UPROPERTY(Category = "Interrupts")
    FHazePlaySequenceData MediumInterrupt;

	UPROPERTY(Category = "Interrupts")
    FHazePlaySequenceData FastInterrupt;

	UPROPERTY(Category = "Interrupts")
    FHazePlaySequenceData BoostInterrupt;

	UPROPERTY(Category = "Interrupts")
    FHazePlaySequenceData BoostWrongInterrupt;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostEnterRight;
		
	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostEnterWrong;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostRightPosition;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostWrongPosition;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostExitRightPosition;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostExitWrongPosition;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostExitRight2Mh;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData BoostExitWrong2Mh;
	
};