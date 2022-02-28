class ULocomotionFeatureWallRun : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWallRun()
    {
        Tag = n"WallRun";
    }

    // The animation when you land on the rail
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  LeftWallRunStart;

    // The MH animation when WallRuning
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  LeftWallRunMH;

    // The animation when you jump while in a WallRun
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  LeftWallRunJump;

    // The animation when you land on the rail
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  RightWallRunStart;

    // The MH animation when WallRuning
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  RightWallRunMH;

    // The animation when you jump while in a WallRun
    UPROPERTY(Category = "Locomotion WallRun")
    FHazePlaySequenceData  RightWallRunJump;
};