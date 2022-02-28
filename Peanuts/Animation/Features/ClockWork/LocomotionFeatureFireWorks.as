class ULocomotionFeatureFireWorks : UHazeLocomotionFeatureBase
{
    default Tag = n"Fireworks";

    UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData Enter; 

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData Launch;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData LaunchInterruptLaunch;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData LaunchInterruptDetonate;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData Detonate;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData DetonateInterruptLaunch;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData DetonateInterruptDetonate;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData Double;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData DoubleMh;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData DoubleExit;

	UPROPERTY(Category = "Fireworks")
    FHazePlaySequenceData Exit;
	
};