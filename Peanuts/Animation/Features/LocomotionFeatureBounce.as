

class ULocomotionFeatureBounce : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureBounce()
    {
        Tag = n"Bounce";
    }

	// General movement

    // 
    UPROPERTY(Category = "Bounce")
    FHazePlaySequenceData Bounce;

	UPROPERTY(Category = "Bounce")
    FHazePlaySequenceData Bounce1;

	UPROPERTY(Category = "Bounce")
    FHazePlaySequenceData Bounce2;

	UPROPERTY(Category = "Bounce")
    FHazePlaySequenceData Bounce3;



	

};