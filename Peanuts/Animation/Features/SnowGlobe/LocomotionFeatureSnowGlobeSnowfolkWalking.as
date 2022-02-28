class ULocomotionFeatureSnowGlobeSnowfolkWalking : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSnowGlobeSnowfolkWalking()
    {
        Tag = n"SnowfolkWalking";
    }

    UPROPERTY(Category = "Idle")
    FHazePlaySequenceData IdleLoop;

    UPROPERTY(Category = "Walking")
    FHazePlayBlendSpaceData WalkLoop;
	
    UPROPERTY(Category = "Frozen")
    FHazePlaySequenceData FrozenLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1LeftImpact;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1RightImpact;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1CollideLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1RebalanceWalkStart;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1Slip;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1SlipLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1SlipWalkStart;

	UPROPERTY(Category = "JumpReaction")
    FHazePlaySequenceData AdditiveSquash;
};