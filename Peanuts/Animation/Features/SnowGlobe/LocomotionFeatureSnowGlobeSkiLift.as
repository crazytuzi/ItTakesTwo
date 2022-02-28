class ULocomotionFeatureSnowGlobeSkiLift : UHazeLocomotionFeatureBase
{

    default Tag = n"SkiLift";

    UPROPERTY(Category = "SkiLift")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "SkiLift")
    FHazePlaySequenceData MhToReady;
    
    UPROPERTY(Category = "SkiLift")
	FHazePlayBlendSpaceData Ready;

	UPROPERTY(Category = "SkiLift")
    FHazePlaySequenceData Exit;
	default Exit.PlayRate = 0.9f;

}