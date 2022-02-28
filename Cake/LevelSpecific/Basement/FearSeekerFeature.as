class ULocomotionFeatureFearSeekerLedge : UHazeLocomotionFeatureBase
{
	//Animations for the first FearSeeker, hanging on the Ledge

   default Tag = n"Ledge";

	//Waiting Mh before triggering encounter
    UPROPERTY(Category = "Intro")
    FHazePlaySequenceData WaitMH;

	UPROPERTY(Category = "Intro")
    FHazePlaySequenceData EmergeStart;

	UPROPERTY(Category = "Intro")
    FHazePlaySequenceData EmergeMH;

	UPROPERTY(Category = "Intro")
    FHazePlaySequenceData EmergeExit;

	UPROPERTY(Category = "Discover")
	FHazePlaySequenceData DiscoverStart;

	UPROPERTY(Category = "Discover")
	FHazePlaySequenceData DiscoverMH;

	UPROPERTY(Category = "Discover")
	FHazePlaySequenceData DiscoverExit;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData SearchMidMH;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData MoveMidToLeft;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData MoveMidToRight;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData SearchLeftMH;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData MoveLeftToMid;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData SearchRightMH;

	UPROPERTY(Category = "Searching")
    FHazePlaySequenceData MoveRightToMid;

};

class ULocomotionFeatureFearSeekerHanging : UHazeLocomotionFeatureBase
{
	//Animations for the second FearSeeker, hanging from the ceiling

   default Tag = n"Hanging";

	UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData Appear;

	//Blendspace for hanging, turning. Has calm and alert state
    UPROPERTY(Category = "Seeking")
    FHazePlayBlendSpaceData HangingMH;

	UPROPERTY(Category = "AlertOverrides")
    FHazePlaySequenceData DiscoverStart;

	UPROPERTY(Category = "AlertOverrides")
    FHazePlaySequenceData DiscoverMH;

	UPROPERTY(Category = "AlertOverrides")
    FHazePlaySequenceData DiscoverReset;
	
};

class ULocomotionFeatureFearSeekerSideways : UHazeLocomotionFeatureBase
{
	//Animations for the third FearSeeker, looking side to side

   default Tag = n"Sideways";

	//Not Alerted

	UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData Appear;

    UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData RightMH;

	UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData RightToLeft;

	UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData LeftMH;

	UPROPERTY(Category = "Seeking")
    FHazePlaySequenceData LeftToRight;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertStartRight;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertRightMH;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertRightToLeft;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertRightReset;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertStartLeft;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertLeftMH;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertLeftToRight;

	UPROPERTY(Category = "Alerted")
    FHazePlaySequenceData AlertLeftReset;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData FaceDiscoverStart;
	
	UPROPERTY(Category = "Face")
    FHazePlaySequenceData FaceDiscoverMh;

	UPROPERTY(Category = "Face")
    FHazePlaySequenceData FaceDiscoverReset;
};
    