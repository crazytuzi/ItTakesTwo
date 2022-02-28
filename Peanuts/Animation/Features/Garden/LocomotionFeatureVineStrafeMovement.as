class ULocomotionFeatureVineStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"VineMovement";


    UPROPERTY(Category = "MH")
    FHazePlayRndSequenceData AimMH;

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

    UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData AimBlendSpace;

	UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData TurnInPlace;

    UPROPERTY(Category = "Whip")
    FHazePlaySequenceData Whip;

	UPROPERTY(Category = "Whip")
    FHazePlaySequenceData WhipActiveStart;

	UPROPERTY(Category = "Whip")
    FHazePlaySequenceData WhipActiveMH;

	UPROPERTY(Category = "Whip")
    FHazePlaySequenceData WhipLetGo;

	UPROPERTY(Category = "Whip")
    FHazePlaySequenceData WhipCatch;

	UPROPERTY(Category = "Whip")
    FHazePlaySequenceData WhipLand;

};