class ULocomotionFeatureSlotCarController : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSlotCarController()
    {
        Tag = n"SlotCarController";
    }

    UPROPERTY()
    FHazePlayBlendSpaceData Idle;

    UPROPERTY()
    FHazePlaySequenceData EnterLeft;

	UPROPERTY()
	FHazePlaySequenceData ExitLeft;

	UPROPERTY()
    FHazePlaySequenceData EnterRight;

    UPROPERTY()
    FHazePlaySequenceData ExitRight;

}
