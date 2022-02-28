class ULocomotionFeatureSwimmingBuoy : UHazeLocomotionFeatureBase
{

	default Tag = n"SwimmingBuoy";

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData ExitFast;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData ExitToMh;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData ExitToNormal;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData ExitToFast;

	UPROPERTY(Category = "SwimmingBuoy")
	FHazePlaySequenceData ExitToCruise;

}