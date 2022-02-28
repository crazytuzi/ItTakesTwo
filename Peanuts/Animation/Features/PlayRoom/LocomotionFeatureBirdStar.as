enum EHazeBirdStarDirection {
	None,
	Up,
	Down,
	Left,
	Right
};


class ULocomotionFeatureBirdStar : UHazeLocomotionFeatureBase
{

    default Tag = n"BirdStar";

    UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData BallBirdMh;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyEnter;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyExit;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayEnter;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayExit;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyMh;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyLeft;	

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyRight;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData CodyMid;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayMh;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayLeft;	

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayRight;

	UPROPERTY(Category = "BirdStar")
    FHazePlaySequenceData MayMid;

};