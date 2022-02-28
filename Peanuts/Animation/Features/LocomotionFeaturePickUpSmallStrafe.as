class ULocomotionFeaturePickUpSmallStrafe: UHazeLocomotionFeatureBase
{
    default Tag = n"PickUpSmallStrafe";

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Equip;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData TurnInPlaceBS;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData Override;

};