class ULocomotionFeatureControlVacuumABP : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureControlVacuumABP()
    {
        Tag = n"ControlVacuumABP";
    }

	UPROPERTY()
	FHazePlaySequenceData IKReference;

	UPROPERTY()
	FHazePlayBlendSpaceData MountedBlendSpace;


}
