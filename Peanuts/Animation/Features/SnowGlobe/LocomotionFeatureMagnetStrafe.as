class ULocomotionFeatureMagnetStrafe: UHazeLocomotionFeatureBase
{
    default Tag = n"MagnetStrafe";

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Equip;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData TurnInPlaceBS;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData Override;

	UPROPERTY(Category = "Inverse Kinematics")
    FHazePlaySequenceData IKReference;

};