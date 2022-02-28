class ULocomotionFeatureGardenVinesSwiper : UHazeLocomotionFeatureBase
{

	default Tag = n"GardenVinesSwiper";

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlaySequenceData Hidden;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlaySequenceData Appear;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlayBlendSpaceData ButtonMashMh;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlayBlendSpaceData StruggleStickInput;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlaySequenceData SwipeAttack;

	UPROPERTY(Category = "GardenVinesSwiper")
	FHazePlaySequenceData Death;

}