enum EHazeMusicDanceDirection {
	None,
	Up,
	Down,
	Left,
	Right
};


class ULocomotionFeatureMusicDance : UHazeLocomotionFeatureBase
{

    default Tag = n"Dance";

    UPROPERTY(Category = "Dance")
    FHazePlaySequenceData DanceMh;

	UPROPERTY(Category = "Dance")
    FHazePlayRndSequenceData DanceMoveLeft;	

	UPROPERTY(Category = "Dance")
    FHazePlayRndSequenceData DanceMoveRight;

	UPROPERTY(Category = "Dance")
    FHazePlayRndSequenceData DanceMoveUp;

};