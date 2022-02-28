class ULocomotionFeatureSnowGlobeSnowfolkSkating : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSnowGlobeSnowfolkSkating()
    {
        Tag = n"SnowfolkSkating";
    }

    UPROPERTY(Category = "Idle")
    FHazePlaySequenceData IdleLoop;

	UPROPERTY(Category = "Idle")
	FHazePlaySequenceData GetReady;

	UPROPERTY(Category = "Idle")
	FHazePlaySequenceData ReadyLoop;

	UPROPERTY(Category = "Frozen")
    FHazePlaySequenceData FrozenLoop;

	UPROPERTY(Category = "Skating")
	FHazePlaySequenceData StartFromReady;

    UPROPERTY(Category = "Skating")
    FHazePlayBlendSpaceData SkateLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1LeftImpact;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1RightImpact;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1CollideLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1RebalanceSkateStart;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1Slip;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1SlipLoop;

    UPROPERTY(Category = "Colliding")
    FHazePlaySequenceData Var1SlipSkateStart;

	UPROPERTY(Category = "JumpReaction")
    FHazePlaySequenceData AdditiveSquash;

};