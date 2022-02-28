class ULocomotionFeatureSpaceGeneratorHead : UHazeLocomotionFeatureBase 
{
    default Tag = n"GeneratorHead";

	//Powered down state
	UPROPERTY(Category = "Head")
    FHazePlaySequenceData InactiveMh;

	//Battery pushed in, no power switch
	UPROPERTY(Category = "Head")
    FHazePlaySequenceData BatteryMh;

	//Power switch, no battery
	UPROPERTY(Category = "Head")
    FHazePlayRndSequenceData Lever;

	//Power switch and battery
	UPROPERTY(Category = "Head")
    FHazePlayRndSequenceData Activate;

	//Powered up state
	UPROPERTY(Category = "Head")
    FHazePlaySequenceData ActiveMh;

	};