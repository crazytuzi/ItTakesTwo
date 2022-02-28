class ULocomotionFeatureFearBat : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureFearBat()
    {
        Tag = n"FearBat";
    }



    UPROPERTY()
    FHazePlaySequenceData FlyMh;

    UPROPERTY()
    FHazePlaySequenceData TargetMh;

	UPROPERTY()
	FHazePlaySequenceData GrabPlayers;

	UPROPERTY()
    FHazePlaySequenceData GrabPlayersFlyMh;

    UPROPERTY()
    FHazePlaySequenceData DropPlayers;

	UPROPERTY()
    FHazePlaySequenceData Crash;

}
