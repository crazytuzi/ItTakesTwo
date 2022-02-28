class ULocomotionFeatureWhackACody : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureWhackACody()
    {
        Tag = n"WhackACody";
    }

	UPROPERTY()
	FHazePlaySequenceData Enter;

	UPROPERTY()
	FHazePlaySequenceData Mh;

	UPROPERTY()
	FHazePlaySequenceData Hit;

	UPROPERTY()
	FHazePlaySequenceData TurnLeft90;

	UPROPERTY()
	FHazePlaySequenceData TurnRight90;

	UPROPERTY()
	FHazePlaySequenceData TurnRight180;


}
