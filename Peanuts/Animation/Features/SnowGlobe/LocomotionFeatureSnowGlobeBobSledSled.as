class ULocomotionFeatureSnowGlobeBobSledSled : UHazeLocomotionFeatureBase
{
	default Tag = n"BobSled";

	UPROPERTY(Category = "Idle")
	FHazePlaySequenceData Idle;

	UPROPERTY()
    float SpeedThreshold = 0.2f;

    UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData StartPushing;

	UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData Pushing;
    
	UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData GetIn;

	UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData GetInSlow;
    
    UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData MovementBlendSpace;

	UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData WhaleSledBlendSpace;

	UPROPERTY(Category = "Jump")
    FHazePlaySequenceData JumpMh;

	UPROPERTY(Category = "Jump")
    FHazePlaySequenceData Jump;
	
	UPROPERTY(Category = "Landing")
    FHazePlaySequenceData Landing;

	UPROPERTY(Category = "Landing")
    FHazePlaySequenceData LandingHeavy;

	UPROPERTY(Category = "Boost")
    FHazePlaySequenceData Boost;

	UPROPERTY(Category = "BoostVariant")
    FHazePlaySequenceData BoostVariant;

	UPROPERTY(Category = "ChimneyJump")
    FHazePlaySequenceData ChimneyJumpStart;

	UPROPERTY(Category = "ChimneyJump")
    FHazePlaySequenceData ChimneyJumpMH;

	UPROPERTY(Category = "ChimneyJump")
    FHazePlaySequenceData ChimneyJumpLanding;

	UPROPERTY(Category = "Collision")
    FHazePlaySequenceData HitFromLeft;

	UPROPERTY(Category = "Collision")
    FHazePlaySequenceData HitFromRight;
};