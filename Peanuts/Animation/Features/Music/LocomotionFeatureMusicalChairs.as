class ULocomotionFeatureMusicalChairs : UHazeLocomotionFeatureBase
{
    default Tag = n"MusicalChairs";

	UPROPERTY(Category = "MusicalChairs")
    FHazePlaySequenceData ReadyMh;

	UPROPERTY(Category = "MusicalChairs")
    FHazePlaySequenceData JogStart;

	UPROPERTY(Category = "MusicalChairs")
    FHazePlaySequenceData JogFwd;

	UPROPERTY(Category = "MusicalChairs")
    FHazePlaySequenceData JogStop;

	};