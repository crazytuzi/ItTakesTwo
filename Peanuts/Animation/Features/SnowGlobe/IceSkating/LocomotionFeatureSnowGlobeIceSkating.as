
class ULocomotionFeatureSnowGlobeIceSkating : UHazeLocomotionFeatureBase
{
   default Tag = n"IceSkating";
    
    UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData IdleAnimations;
    
    UPROPERTY(Category = "StartAnimations")
    FHazePlaySequenceData StartAnimation;
    
    UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData StopAnimation;

	UPROPERTY(Category = "MovementAnimations")
	FHazePlaySequenceData FromRightBoost;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData MovementBlendSpace;

	UPROPERTY(Category = "GlideAnimations")
    FHazePlayBlendSpaceData Gliding;
	float Glide_Blend = 0.2f;

	UPROPERTY(Category = "GlideAnimations")
    FHazePlaySequenceData GlideStop;

};