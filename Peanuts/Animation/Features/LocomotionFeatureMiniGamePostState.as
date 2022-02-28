import Peanuts.Animation.AnimationStatics;

class ULocomotionFeatureMiniGamePostState : UHazeLocomotionFeatureBase
{

	default Tag = n"MiniGame";

	UPROPERTY(Category = "Won")
	FHazePlayRndSequenceData Won;

	UPROPERTY(Category = "Lost")
	FHazePlayRndSequenceData Lost;

}

