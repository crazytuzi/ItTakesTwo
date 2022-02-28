class ULocomotionFeatureTrainRide : UHazeLocomotionFeatureBase 
{

    default Tag = n"TrainRide";

    
    UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData Start;

    UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData DownHillBegin;

	UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData DownHillMH;

	UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData DownHillOver;

	UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData Whistle;

	UPROPERTY(Category = "Locomotive")
    FHazePlaySequenceData Exit;

    UPROPERTY(Category = "Carriage")
    FHazePlaySequenceData CarriageMH;

	UPROPERTY(Category = "Carriage")
    FHazePlaySequenceData CarriageDownHillBegin;

	UPROPERTY(Category = "Carriage")
    FHazePlaySequenceData CarriageDownHillMH;

	UPROPERTY(Category = "Carriage")
    FHazePlaySequenceData CarriageDownHillOver;
    
	UPROPERTY(Category = "Carriage")
    FHazePlaySequenceData CarriageExit;

}