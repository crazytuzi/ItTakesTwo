class ULocomotionFeatureClockWorkPedalBoat : UHazeLocomotionFeatureBase
{

    default Tag = n"PedalBoat";

	UPROPERTY(Category = "PedalBoat")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "PedalBoat")
    FHazePlaySequenceData PedalBoatMh;

	UPROPERTY(Category = "PedalBoat")
    FHazePlaySequenceData PedalProgress;



}