class ULocomotionFeatureMusicTrackRunner : UHazeLocomotionFeatureBase
{

    default Tag = n"TrackRunner";

    UPROPERTY(Category = "TrackRunner")
    FHazePlaySequenceData Sprint;
		
	UPROPERTY(Category= "TrackRunner")
	FHazePlayRndSequenceData DashL;

	UPROPERTY(Category= "TrackRunner")
	FHazePlayRndSequenceData DashR;

	UPROPERTY(Category= "TrackRunner")
	FHazePlayRndSequenceData Jump;

	UPROPERTY(Category= "TrackRunner")
	FHazePlaySequenceData WarmUp;

	UPROPERTY(Category= "TrackRunner")
	FHazePlaySequenceData Impact;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortJump;

	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortDash;

	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortImpact;



    // Example of BlendSpace data
    // UPROPERTY(Category = "TrackRunner")
	// FHazePlayBlendspaceData Blendspace;

}