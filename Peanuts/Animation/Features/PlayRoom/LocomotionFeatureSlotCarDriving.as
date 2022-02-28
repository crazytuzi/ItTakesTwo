class ULocomotionFeatureSlotCarDriving : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSlotCarDriving()
    {
        Tag = n"SlotCarDriving";
    }

    UPROPERTY()
    FHazePlayBlendSpaceData Idle;

    UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
	FHazePlaySequenceData Exit;

}
