

// Take Damage
class ULocomotionFeatureTakeBullBossDamage : UHazeLocomotionFeatureBase
{
   default Tag = n"TakeBullBossDamage";
    
    UPROPERTY(Category = "Throws")
    FHazePlayRndSequenceData Stomped;

	UPROPERTY(Category = "Throws")
    FHazePlayRndSequenceData LeftForced;

	UPROPERTY(Category = "Throws")
    FHazePlayRndSequenceData RightForce;

	UPROPERTY(Category = "Throws")
    FHazePlayRndSequenceData MovementDirectionForced;

	UPROPERTY(Category = "MH")
    FHazePlaySequenceData StandardMH;

	UPROPERTY(Category = "Recovery")
	FHazePlaySequenceData Recovery;

	UPROPERTY(Category = "HeadAttach")
	FHazePlaySequenceData HeadStompAttach;

	UPROPERTY(Category = "HeadAttach")
	FHazePlaySequenceData HeadRightAttach;

	UPROPERTY(Category = "HeadAttach")
	FHazePlaySequenceData HeadLeftAttach;

	UPROPERTY(Category = "HeadAttach")
	FHazePlaySequenceData HeadDirectionAttach;

	UPROPERTY(Category = "LeftFrontFootAttach")
	FHazePlaySequenceData LFfootStompAttach;

	UPROPERTY(Category = "LeftFrontFootAttach")
	FHazePlaySequenceData LFfootRightAttach;

	UPROPERTY(Category = "LeftFrontFootAttach")
	FHazePlaySequenceData LFfootLeftAttach;

	UPROPERTY(Category = "LeftFrontFootAttach")
	FHazePlaySequenceData LFfootDirectionAttach;

	UPROPERTY(Category = "RightFrontFootAttach")
	FHazePlaySequenceData RFfootStompAttach;

	UPROPERTY(Category = "RightFrontFootAttach")
	FHazePlaySequenceData RFfootRightAttach;

	UPROPERTY(Category = "RightFrontFootAttach")
	FHazePlaySequenceData RFfootLeftAttach;

	UPROPERTY(Category = "RightFrontFootAttach")
	FHazePlaySequenceData RFfootDirectionAttach;

	UPROPERTY(Category = "BackFootAttach")
	FHazePlaySequenceData LBfootAttach;

	UPROPERTY(Category = "BackFootAttach")
	FHazePlaySequenceData RBfootAttach;
};
