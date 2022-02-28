class USleepingMoleFeature : UHazeLocomotionFeatureBase
{
    USleepingMoleFeature()
    {
        Tag = n"MoleSleep";
    }

	UPROPERTY(Category = "MoleSleep")
    FHazePlaySequenceData SleepVar_1;
	UPROPERTY(Category = "MoleSleep")
    FHazePlaySequenceData SleepVar_2;
	UPROPERTY(Category = "MoleSleep")
    FHazePlaySequenceData RollOverLeft;

	//These top three can be removed later, but left in for now to not mess anything up 

	//Alertness Blendspaces

	UPROPERTY(Category = "MoleSleep")
	FHazePlayBlendSpaceData BackSleep;

	UPROPERTY(Category = "MoleSleep")
	FHazePlayBlendSpaceData BellySleep;

	//Animations played if the player interacts with the moles

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BackBounce;

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BellyBounce;

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BellyHose;

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BackHose;

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BellyVine;

	UPROPERTY(Category = "Reactions")
	FHazePlaySequenceData BackVine;	

	UPROPERTY(Category = "RollOver")
	FHazePlaySequenceData RollToBellyLeft;
	
	UPROPERTY(Category = "RollOver")
	FHazePlaySequenceData RollToBellyRight;
	
	UPROPERTY(Category = "RollOver")
	FHazePlaySequenceData RollToBackLeft;
	
	UPROPERTY(Category = "RollOver")
	FHazePlaySequenceData RollToBackRight;


};