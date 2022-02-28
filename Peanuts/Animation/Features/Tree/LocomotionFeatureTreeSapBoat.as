class ULocomotionFeatureSapBoat : UHazeLocomotionFeatureBase
{
    default Tag = n"SapBoat";

    UPROPERTY(Category = "SapBoat")
    FHazePlaySequenceData Enter; 

	UPROPERTY(Category = "SapBoat")
    FHazePlayBlendSpaceData Steering;

	UPROPERTY(Category = "SapBoat")
    FHazePlaySequenceData Exit;
	
};