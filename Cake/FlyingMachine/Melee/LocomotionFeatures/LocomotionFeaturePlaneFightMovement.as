
class ULocomotionFeaturePlaneFightMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

    UPROPERTY(Category = "Animation")
    FHazePlayRndSequenceData IdleAnimations;

	UPROPERTY(Category = "Animation")
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY(Category = "Animation Squirrel")
    bool bLeft;

    UPROPERTY(Category = "Animation Squirrel")
    FHazePlaySequenceData Mh;

    UPROPERTY(Category = "Animation Squirrel")
    FHazePlaySequenceData Fwd;

    UPROPERTY(Category = "Animation Squirrel")
    FHazePlaySequenceData Bck;

    
    
};