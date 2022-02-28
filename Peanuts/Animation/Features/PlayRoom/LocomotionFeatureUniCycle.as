class ULocomotionFeatureUniCycle : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureUniCycle()
    {
        Tag = n"UniCycle";
    }
	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData EnterPiggyBack;

	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData SecondEnter;

	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData MhPiggyBack;

	UPROPERTY(Category = "MH & Enter")
    FHazePlaySequenceData Stabilize;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Movement;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData MovementPiggyBAck;

	UPROPERTY(Category = "LeanBlendSpace")
    FHazePlayBlendSpaceData LeanBlendSpace;

	UPROPERTY(Category = "LeanBlendSpace")
    FHazePlayBlendSpaceData LeanBlendSpacePiggyBack;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData FailFwd;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData FailFwdPiggyBack;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData FailBwd;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData FailBwdPiggyBack;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData Finish;

	UPROPERTY(Category = "Fail & Exit")
    FHazePlaySequenceData FinishPiggyBack;	
};