class UPlayerCutieArmsPullFeature : UHazeLocomotionFeatureBase
{
    UPlayerCutieArmsPullFeature()
    {
        Tag = n"EdgeHang";
    }

    UPROPERTY(Category = "MH")
    FHazePlaySequenceData PullArmMH;

	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData CodyEnter;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData CodyExit;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData MayEnter;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData MayExit;

	UPROPERTY(Category = "Struggle")
	FHazePlaySequenceData CodyStruggle;
	UPROPERTY(Category = "Struggle")
    FHazePlaySequenceData MayStruggle;
	UPROPERTY(Category = "Struggle")
    FHazePlaySequenceData BothStruggle;
};