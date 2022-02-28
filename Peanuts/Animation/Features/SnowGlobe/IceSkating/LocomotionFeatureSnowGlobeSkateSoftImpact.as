class ULocomotionFeatureSnowGlobeSkateSoftImpact : UHazeLocomotionFeatureBase
{
     default Tag = n"SkateSoftImpact";

	UPROPERTY(Category = "Impacts")
	FHazePlaySequenceData LeftImpact;

	UPROPERTY(Category = "Impacts")
	FHazePlaySequenceData RightImpact;
};