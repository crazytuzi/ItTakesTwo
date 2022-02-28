
class ULocomotionFeatureRotateCrane : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureRotateCrane()
    {
        Tag = n"RotateCrane";
    }

	UPROPERTY()
    FHazePlaySequenceData MH;

    UPROPERTY()
    FHazePlaySequenceData Push;

    UPROPERTY()
    FHazePlaySequenceData Pull;
}