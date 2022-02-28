

class ULocomotionFeaturePushBattery : UHazeLocomotionFeatureBase 
{


    ULocomotionFeaturePushBattery()
    {
        Tag = n"PushBattery";
    }

	// General movement

    // 
    UPROPERTY(Category = "Cody")
    FHazePlaySequenceData PushFwd;

	UPROPERTY(Category = "Cody")
    FHazePlaySequenceData PushBck;

	UPROPERTY(Category = "Battery")
    FHazePlaySequenceData BatteryFwd;

	UPROPERTY(Category = "Battery")
    FHazePlaySequenceData BatteryBck;



	

};