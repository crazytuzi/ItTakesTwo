class ULocomotionFeatureTreeBeetleRiding : UHazeLocomotionFeatureBase
{
    default Tag = n"BeetleRiding";

    UPROPERTY(Category = "BeetleRiding")
    FHazePlaySequenceData BeetleRidingWaiting;

	UPROPERTY(Category = "BeetleRiding")
    FHazePlaySequenceData BeetleRidingBegin;

    UPROPERTY(Category = "BeetleRiding")
    FHazePlayBlendSpaceData BeetleRidingRunningBS;

    UPROPERTY(Category = "BeetleRiding")
    FHazePlaySequenceData BeetleRidingAttack;

    UPROPERTY(Category = "BeetleJump")
    FHazePlaySequenceData JumpStart;

	UPROPERTY(Category = "BeetleJump")
    FHazePlaySequenceData JumpMH;

	UPROPERTY(Category = "BeetleJump")
    FHazePlaySequenceData JumpLand;

	UPROPERTY(Category = "BeetleRiding")
    FHazePlayBlendSpaceData BeetleRidingAim;

    UPROPERTY(Category = "BeetleRiding")
    FHazePlaySequenceData BeetleRidingShoot;

	UPROPERTY(Category = "Death")
    FHazePlaySequenceData CrashOnGround;
	
	UPROPERTY(Category = "Death")
    FHazePlaySequenceData CrashInAir;
	
	UPROPERTY(Category = "Death")
    FHazePlaySequenceData Falling;

};