class ULocomotionFeatureFearArm : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureFearArm()
    {
        Tag = n"FearArm";
    }

    // Mh
    UPROPERTY(Category = "FearBoss")
    FHazePlaySequenceData SubmergedMH;

	UPROPERTY(Category = "FearBoss")
    FHazePlaySequenceData EmergeAttack;

	UPROPERTY(Category = "FearBoss")
    FHazePlaySequenceData GrabPlayer;
	
}
