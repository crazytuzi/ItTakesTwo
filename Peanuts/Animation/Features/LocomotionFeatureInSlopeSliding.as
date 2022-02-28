import Peanuts.Animation.Features.LocomotionFeatureInSlopeSlidingAim;

enum EHazeAnimationSlopeSlidingExitType {
	Jump,
	SlideOfEdge,
	Movement,
}

enum EHazeAnimationSlopeSlidingEnterType {
	DefaultEnter,
	GroundPound,
	Falling,
	Dash
}

class ULocomotionFeatureSlopeSliding : UHazeLocomotionFeatureBase
{

    default Tag = FeatureName::SlopeSliding;


	// If this is true, blendspaces are used for going into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	bool UseBlendspacesToMovement = false;

    UPROPERTY(Category = "Slope Sliding Enters")
    FHazePlaySequenceData SlopeSlidingEnter;

	UPROPERTY(Category = "Slope Sliding Enters")
    FHazePlaySequenceData SlopeSlidingEnterDash;

    UPROPERTY(Category = "Slope Sliding Enters")
    FHazePlaySequenceData SlopeSlidingEnterGroundPound;

    UPROPERTY(Category = "Slope Sliding Enters")
    FHazePlaySequenceData SlopeSlidingEnterFalling;

    UPROPERTY(Category = "Slope Sliding")
    FHazePlayBlendSpaceData SlopeSliding;

    UPROPERTY(Category = "Slope Sliding Exits")
    FHazePlaySequenceData SlopeSlidingExitFalling;

    UPROPERTY(Category = "Slope Sliding Exits")
    FHazePlayRndSequenceData SlopeSlidingExitJump;

    UPROPERTY(Category = "Slope Sliding Exits")
    FHazePlaySequenceData SlopeSlidingExitToMovement;

    UPROPERTY(Category = "Slope Sliding Exits")
    FHazePlayBlendSpaceData SlopeSlidingExitToMovementBS;	

	UPROPERTY(Category = "HitReaction")
    FHazePlaySequenceData StungByWasp;

	UPROPERTY(Category = "HitReaction")
    FHazePlaySequenceData StungByWaspInAir;

	UPROPERTY(Category = "Weapon")
	bool bPlayerHasWeapons;

};