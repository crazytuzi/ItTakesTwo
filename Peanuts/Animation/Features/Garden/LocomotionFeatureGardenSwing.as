class ULocomotionFeatureGardenSwing : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGardenSwing()
    {
        Tag = n"SwingingMinigame";
    }

    UPROPERTY()
    FHazePlaySequenceData Idle;

	UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlaySequenceData Swinging;

};