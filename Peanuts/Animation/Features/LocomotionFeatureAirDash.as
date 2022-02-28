class ULocomotionFeatureAirDash : UHazeLocomotionFeatureBase
{

    default Tag = n"AirDash";
    
    UPROPERTY()
    FHazePlaySequenceData AirDash;

	// This will move the root of the character backwards when going into a wall to avoid clipping. Try to keep this value as close to 0 as possible.
	UPROPERTY(Category = "Into Wall Movement")
    float RootXTranslation = -70.f;



	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
};