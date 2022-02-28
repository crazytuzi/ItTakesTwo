class ULocomotionFeatureCurlingSnowFolk : UHazeLocomotionFeatureBase
{
	UPROPERTY(Category = "Idle")
    FHazePlaySequenceData Idle;

	UPROPERTY(Category = "Talking")
    FHazePlaySequenceData Talking;

	UPROPERTY(Category = "Reactions")
	FHazePlayRndSequenceData ReactionsVocal;

	UPROPERTY(Category = "Reactions")
	FHazePlayRndSequenceData ReactionsClapping;
}