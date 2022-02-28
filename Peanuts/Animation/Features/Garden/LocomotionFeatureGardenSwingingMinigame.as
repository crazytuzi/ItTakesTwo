class ULocomotionFeatureSwingingMinigame : UHazeLocomotionFeatureBase
{

	default Tag = n"SwingingMinigame";

	UPROPERTY(Category = "Swinging")
	FHazePlayBlendSpaceData Mh;

	//Additive animation following the direction the swing is going in, not the player's input
	UPROPERTY(Category = "Swinging")
	FHazePlayBlendSpaceData DirectionAdd;

	UPROPERTY(Category = "Swinging")
	FHazePlaySequenceData JumpFwd;

	UPROPERTY(Category = "Swinging")
	FHazePlaySequenceData JumpBwd;

	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData FailStart;

	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData Falling;

	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData FailLand;


}