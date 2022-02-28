class ULocomotionFeatureGardenGardenWateringPlant : UHazeLocomotionFeatureBase
{

    default Tag = n"GardenWateringPlant";

    UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData ClosedMH;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData OpenMH;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData VineAttach;
	
	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData VineDetach;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlayBlendSpaceData DrinkingBS;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlayBlendSpaceData RechargeBS;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData FinishedSwallow;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlaySequenceData FinishedMH;

	UPROPERTY(Category = "GardenWateringPlant")
    FHazePlayBlendSpaceData WaterAmount;

     // Example of BlendSpace data
    // UPROPERTY(Category = "GardenWateringPlant")
	// FHazePlayBlendSpaceData Blendspace;
}