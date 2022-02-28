class ULocomotionFeatureFearBoss : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureFearBoss()
    {
        Tag = n"FearBoss";
    }

	UPROPERTY(Category = "Phase1")
	FHazePlaySequenceData FirstPhaseMh;

	UPROPERTY(Category = "Phase1")
	FHazePlaySequenceData BatAttack;

	UPROPERTY(Category = "Phase1")
	FHazePlaySequenceData FirstPhaseRetreat;


	// Phase 2
	UPROPERTY(Category = "Phase2")
	FHazePlaySequenceData SecondPhaseMh;

	UPROPERTY(Category = "Phase2")
	FHazePlaySequenceData BreathAttackLeft;

	UPROPERTY(Category = "Phase2")
	FHazePlaySequenceData BreathAttackRight;

	UPROPERTY(Category = "Phase2")
	FHazePlaySequenceData SecondPhaseRetreat;

	// Phase 3
	UPROPERTY(Category = "Phase3")
	FHazePlaySequenceData ThirdPhaseMh;

	UPROPERTY(Category = "Phase3")
	FHazePlaySequenceData SweepAttackLeft;

	UPROPERTY(Category = "Phase3")
	FHazePlaySequenceData SweepAttackRight;

	UPROPERTY(Category = "Phase3")
	FHazePlaySequenceData ThirdPhaseRetreat;

	// Phase 4
	UPROPERTY(Category = "Phase4")
	FHazePlaySequenceData FourthPhaseMh;

	UPROPERTY(Category = "Phase4")
	FHazePlaySequenceData HandTsunamiAttack;

	UPROPERTY(Category = "Phase4")
	FHazePlaySequenceData FourthPhaseRetreat;

	// Phase 5
	UPROPERTY(Category = "Phase5")
	FHazePlaySequenceData FifthPhaseMh;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftAttackRightUp;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftDownRightUpMH;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftRecoverRightUp;
   
    UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftUpRightAttack;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftUpRightDownMH;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftUpRightRecover;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData LeftGrabPlayers;

	UPROPERTY(Category = "Phase5")
    FHazePlaySequenceData RightGrabPlayers;
}