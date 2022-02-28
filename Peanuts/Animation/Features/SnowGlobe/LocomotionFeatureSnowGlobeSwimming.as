class ULocomotionFeatureSnowGlobeSwimming : UHazeLocomotionFeatureBase
{
    default Tag = n"Swimming";

    // 1D Blendspace containing Mh down (-90), Mh (0) & Mh up (90)
    UPROPERTY(Category = "Swimming")
    FHazePlayBlendSpaceData Idle;

    // 2D Blendspace with swimming animations & banking. Values range between X: -100 to 100, Y: -90 to 90
    UPROPERTY(Category = "Swimming")
    FHazePlayBlendSpaceData Swim;

	UPROPERTY(Category = "Swimming")
    FHazePlayBlendSpaceData SwimFast;

	UPROPERTY(Category = "Swimming")
    FHazePlaySequenceData SwimFastToSlow;

	UPROPERTY(Category = "Swimming")
    FHazePlayBlendSpaceData Cruise;

	UPROPERTY(Category = "Swimming")
    FHazePlaySequenceData CruiseToFast;

};