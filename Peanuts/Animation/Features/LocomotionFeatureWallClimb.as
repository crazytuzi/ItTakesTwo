class ULocomotionFeatureWallClimb : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWallClimb()
    {
        Tag = n"WallClimb";
    }

    UPROPERTY(Category = "WallClimb BlendSpace")
    FHazePlayBlendSpaceData WallClimb;

	UPROPERTY(Category = "WallClimb BlendSpace")
    FHazePlaySequenceData WallClimbEnter;

};