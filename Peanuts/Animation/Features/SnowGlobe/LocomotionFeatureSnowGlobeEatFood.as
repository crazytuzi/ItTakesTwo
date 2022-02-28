class ULocomotionFeatureSnowGlobeEatFood : UHazeLocomotionFeatureBase
{

    default Tag = n"EatFood";

    UPROPERTY(Category = "EatFood")
    FHazePlaySequenceData EatFoodLeft;

	UPROPERTY(Category = "EatFood")
    FHazePlaySequenceData EatFoodRight;
    
    // Example of BlendSpace data
    // UPROPERTY(Category = "EatFood")
	// FHazePlayBlendSpaceData Blendspace;

}