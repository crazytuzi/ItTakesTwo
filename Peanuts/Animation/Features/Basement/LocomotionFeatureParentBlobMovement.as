class ULocomotionFeatureParentBlobMovement : UHazeLocomotionFeatureBase
{
   default Tag = n"Movement";
    
    UPROPERTY()
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY()
    FHazePlayBlendSpaceData CodyBlendSpace;

    UPROPERTY()
    FHazePlayBlendSpaceData MayBlendSPace;

    UPROPERTY()
    FHazePlayBlendSpaceData CodyArmBlendSpace;

    UPROPERTY()
    FHazePlayBlendSpaceData MayArmBlendSpace;

	UPROPERTY()
    FHazePlayBlendSpaceData Opposed;

    UPROPERTY()
    FHazePlaySequenceData ShootArmOverride;

    UPROPERTY()
    FHazePlaySequenceData CodyShoot;

    UPROPERTY()
    FHazePlaySequenceData MayShoot;
};