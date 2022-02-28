class ULocomotionFeatureGardenSpaBath : UHazeLocomotionFeatureBase
{

    default Tag = n"SpaBath";

	UPROPERTY(Category = "SpaBath")
    FHazePlayRndSequenceData BathMh;

	UPROPERTY(Category = "SpaBath")
    FHazePlaySequenceData Exit;

    // Example of BlendSpace data
    // UPROPERTY(Category = "SpaBath")
	// FHazePlayBlendSpaceData Blendspace;

}