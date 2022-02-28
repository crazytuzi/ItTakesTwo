class ULocomotionFeatureCurling : UHazeLocomotionFeatureBase
{
    default Tag = n"Curling";

    UPROPERTY(Category = "Curling")
    FHazePlaySequenceData Enter; 

	UPROPERTY(Category = "Curling")
    FHazePlayBlendSpaceData Strafe;

	UPROPERTY(Category = "Curling")
	FHazePlayBlendSpaceData Turn;

	UPROPERTY(Category = "Curling")
	FHazePlayBlendSpaceData Glide;

	UPROPERTY(Category = "Curling")
    FHazePlaySequenceData Exit; 

	UPROPERTY(Category = "Curling")
    FHazePlaySequenceData ChargeStart; 

	UPROPERTY(Category = "Curling")
    FHazePlayBlendSpaceData Charge;

	UPROPERTY(Category = "Curling")
    FHazePlaySequenceData Shoot; 

	UPROPERTY(Category = "Curling")
    FHazePlayBlendSpaceData ShootBS;
	
};