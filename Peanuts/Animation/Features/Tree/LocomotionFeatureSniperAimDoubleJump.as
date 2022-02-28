class ULocomotionFeatureSniperAimDoubleJump : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSniperAimDoubleJump()
    {
        Tag = n"DoubleJump";
    }

    UPROPERTY()
    FHazePlaySequenceData DoubleJump;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData Shoot;

    UPROPERTY(Category = "Shooting")
    FHazePlaySequenceData FinalShot;

};