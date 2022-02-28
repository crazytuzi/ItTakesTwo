class ULocomotionFeatureDiscoBall : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureDiscoBall()
    {
        Tag = n"DiscoBall";
    }

    UPROPERTY()
    FHazePlaySequenceData DiscoBallMoveLeft;

	UPROPERTY()
    FHazePlaySequenceData DiscoBallMoveRight;

}