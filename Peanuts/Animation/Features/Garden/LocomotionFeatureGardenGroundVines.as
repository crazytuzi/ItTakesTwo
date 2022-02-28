class ULocomotionFeatureGardenGroundVines : UHazeLocomotionFeatureBase
{
    default Tag = n"GardenGroundVines";

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData Hidden;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData PlateFallDown;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData Appear;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData HitReactionPlateDestroyed;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData MhNoPlate;

	UPROPERTY(Category = "GroundVines")
	FHazePlaySequenceData Exit;

}