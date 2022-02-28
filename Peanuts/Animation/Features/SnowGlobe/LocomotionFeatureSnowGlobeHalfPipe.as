class ULocomotionFeatureSnowGlobeHalfPipe : UHazeLocomotionFeatureBase
{

    default Tag = n"HalfPipe";

	UPROPERTY(Category = "HalfPipe")
    FHazePlaySequenceData Enter;

    UPROPERTY(Category = "HalfPipe")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "HalfPipe")
    FHazePlaySequenceData InAirFwd;

	UPROPERTY(Category = "HalfPipe")
    FHazePlaySequenceData InAirBck;

	UPROPERTY(Category = "HalfPipe")
    FHazePlaySequenceData LandingFwd;

	UPROPERTY(Category = "HalfPipe")
    FHazePlaySequenceData LandingBck;

	UPROPERTY(Category = "HalfPipe")
    FHazePlayRndSequenceData Trick;

}