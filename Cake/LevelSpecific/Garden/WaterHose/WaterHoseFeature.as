class ULocomotionFeatureWaterHose : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureWaterHose()
    {
        Tag = n"WaterHose";
    }

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData JogBlendspace;

    UPROPERTY(Category = "Aim")
    FHazePlaySequenceData MhToAim;

    UPROPERTY(Category = "Aim")
    FHazePlaySequenceData SickleToAim;

	UPROPERTY(Category = "Aim")
	FHazePlaySequenceData AimMH;

	UPROPERTY(Category = "Aim")
	FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(Category = "Aim")
	FHazePlayBlendSpaceData ShootAimSpace;

	UPROPERTY(Category = "Aim")
	FHazePlaySequenceData AimToMh;

	UPROPERTY(Category = "Aim")
	FHazePlaySequenceData AimToSickle;

	UPROPERTY(Category = "LeftHandOverride")
	FHazePlaySequenceData LeftHandOverride;


}
