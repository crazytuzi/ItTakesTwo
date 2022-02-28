class ULocomotionFeaturePlayRoomPullBackCar : UHazeLocomotionFeatureBase
{

    default Tag = n"PullBackCar";

    UPROPERTY(Category = )
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = )
    FHazePlayBlendSpaceData PullBackCarBS;

    UPROPERTY(Category = )
    FHazePlaySequenceData Release;

	UPROPERTY(Category = )
    FHazePlaySequenceData IkRef;
    
    // Example of BlendSpace data
    // UPROPERTY(Category = "PullBackCar")
	// FHazePlayBlendspaceData Blendspace;

}