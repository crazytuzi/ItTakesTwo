class ULocomotionFeatureDashTo : UHazeLocomotionFeatureBase
{

    default Tag = n"DashTo";
    
   	UPROPERTY()
    FHazePlayBlendSpaceData DashStartBS;

	UPROPERTY()
	FHazePlayBlendSpaceData DashStartInAirBS;

	
	/*VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;*/
};