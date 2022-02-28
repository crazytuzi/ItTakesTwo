class ULocomotionFeatureLarvaBasket : UHazeLocomotionFeatureBase 
{
	default Tag = n"LarvaBasket";

	UPROPERTY()
	FHazePlaySequenceData MH;

	UPROPERTY()
	FHazePlaySequenceData JumpStart;

	UPROPERTY()
	FHazePlaySequenceData Falling;

	UPROPERTY()
	FHazePlaySequenceData Land;

	UPROPERTY()
	FHazePlaySequenceData GrabBall;

	UPROPERTY()
	FHazePlaySequenceData ThrowGround;

	UPROPERTY()
	FHazePlaySequenceData ThrowAir;

	UPROPERTY()
	FHazePlaySequenceData Exit;
};