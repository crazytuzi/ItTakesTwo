class ULocomotionFeaturePerfectDash : UHazeLocomotionFeatureBase
{
	default Tag = n"PerfectDash";
	
	// If this is true, blendspaces are used for dashing and going into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	
	bool UseBlendspacesToMovement = false;

	UPROPERTY(Category = "Locomotion Perfect Dash")
    FHazePlaySequenceData PerfectDash;
	
	UPROPERTY(Category = "Stops")
    FHazePlaySequenceData PerfectDashStop;

	UPROPERTY(Category = "Stops")
    FHazePlaySequenceData PerfectDashStopInMotion;

	// This only plays if Use Blendspaces to Movement is true
    UPROPERTY(Category = "Stops")
    FHazePlayBlendSpaceData PerfectDashStopInMotionBS;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
	
};