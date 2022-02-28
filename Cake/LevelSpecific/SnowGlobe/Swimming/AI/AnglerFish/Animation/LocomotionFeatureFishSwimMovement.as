
class ULocomotionFeatureFishSwimMovement : UHazeLocomotionFeatureBase
{
	default Tag = FeatureName::Swimming;

	UPROPERTY(Category = "Animation")
	FHazePlayBlendSpaceData SwimBS;

	UPROPERTY(Category = "Animation")
	FHazePlayBlendSpaceData LungeBS;

	UPROPERTY(Category = "Animation")
	FHazePlayBlendSpaceData GapingBlendspace;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData BiteStart;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData BiteAnimations;
	


	
};