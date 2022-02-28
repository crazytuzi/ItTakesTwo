class ULocomotionFeatureSnowGlobeFastBrake : UHazeLocomotionFeatureBase
{
	default Tag = n"FastBrake";

	UPROPERTY(Category = "Braking")
    FHazePlaySequenceData FastBrake;

	UPROPERTY(Category = "Braking")
	FHazePlaySequenceData BrakingMH;

	UPROPERTY(Category = "Braking")
	FHazePlaySequenceData BrakeStop;

	UPROPERTY(Category = "Braking")
	FHazePlaySequenceData Turning180;

};