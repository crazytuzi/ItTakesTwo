class ULocomotionFeatureSnowGlobeSkateGrind : UHazeLocomotionFeatureBase
{
	default Tag = n"SkateGrind";

	UPROPERTY(Category = OnRail)
    FHazePlayBlendSpaceData MH;

	UPROPERTY(Category = OnRail)
    FHazePlayRndSequenceData Dash;

	UPROPERTY(Category = OnRail)
    FHazePlayRndSequenceData DashVariant;

	UPROPERTY(Category = ToRail)
    FHazePlaySequenceData EnterFromLeft;
	
	UPROPERTY(Category = ToRail)
    FHazePlaySequenceData EnterFromRight;
	
	UPROPERTY(Category = ToRail)
	FHazePlaySequenceData LandFwd;

	UPROPERTY(Category = ToRail)
    FHazePlaySequenceData LandFromLeft;
	
	UPROPERTY(Category = ToRail)
    FHazePlaySequenceData LandFromRight;

	UPROPERTY(Category = FromRail)
    FHazePlayRndSequenceData JumpA;

	UPROPERTY(Category = FromRail)
    FHazePlayRndSequenceData JumpB;


};