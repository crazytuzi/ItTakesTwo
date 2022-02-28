class ULocomotionFeatureGardenGardenLeafPod : UHazeLocomotionFeatureBase
{

    default Tag = n"GardenLeafPod";

    UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData PollenPuff;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData VineAttach;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData VineDetach;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Hit1;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Hit2;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Hit3;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlayRndSequenceData Hits;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Death;
    
    // Example of BlendSpace data
    // UPROPERTY(Category = "GardenLeafPod")
	// FHazePlayBlendSpaceData Blendspace;

}