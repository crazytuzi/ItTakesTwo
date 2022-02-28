class ULocomotionFeatureNailRecallStrafe: UHazeLocomotionFeatureBase
{
    default Tag = n"NailRecallStrafe";


	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData TurnInPlace;
};