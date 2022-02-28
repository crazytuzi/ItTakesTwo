class ULocomotionFeaturePlayRoomPullBackCarSit : UHazeLocomotionFeatureBase
{

    default Tag = n"PullBackCarSit";

	UPROPERTY(Category = )
    FHazePlaySequenceData SitMH;

    UPROPERTY(Category = )
    FHazePlayBlendSpaceData LaunchBS;


	UPROPERTY(Category = )
    FHazePlaySequenceData IkRef;
    
    // Example of BlendSpace data
    // UPROPERTY(Category = "PullBackCar")
	// FHazePlayBlendspaceData Blendspace;

}