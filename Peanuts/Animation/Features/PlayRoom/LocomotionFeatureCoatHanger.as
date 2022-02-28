class ULocomotionFeatureCoatHanger: UHazeLocomotionFeatureBase
{
   default Tag = n"CoatHanger";

	UPROPERTY()
    bool bUseIK;

    UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlayBlendSpaceData HangBS;

	UPROPERTY()
    FHazePlaySequenceData ThrownOff;

	

};