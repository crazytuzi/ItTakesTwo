class ULocomotionFeatureCymbalStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";


    UPROPERTY(Category = "MH")
    FHazePlayRndSequenceData AimMH;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData ShieldBlendSpace;

    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimBlendSpace;

	UPROPERTY(Category = "Aiming")
	FHazePlayBlendSpaceData AimTurnInPlaceBlendSpace;

    UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData ThrownLand;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Catch;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData Unequip;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData EquipThrow;

	UPROPERTY(Category = "Throw")
    FHazePlaySequenceData UnequipThrow;

	UPROPERTY(Category = "Shield")
    FHazePlaySequenceData EquipShield;

	UPROPERTY(Category = "Shield")
	FHazePlayBlendSpaceData ShieldTurnInPlaceBlendSpace;

};