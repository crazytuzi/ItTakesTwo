class UPlayerCutieLegPullFeature : UHazeLocomotionFeatureBase
{
    UPlayerCutieLegPullFeature()
    {
        Tag = n"LegPull";
    }

    UPROPERTY(Category = "MH")
    FHazePlayBlendSpaceData PullLegMH;

	UPROPERTY(Category = "EntersAndExits")
    FHazePlayBlendSpaceData CodyEnter;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlayBlendSpaceData CodyExit;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlayBlendSpaceData MayEnter;
	UPROPERTY(Category = "EntersAndExits")
    FHazePlayBlendSpaceData MayExit;

	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData LocalCodyExit;

	UPROPERTY(Category = "EntersAndExits")
    FHazePlaySequenceData LocalMayExit;


	UPROPERTY(Category = "Struggle")
	FHazePlayBlendSpaceData CodyStruggle;
	UPROPERTY(Category = "Struggle")
    FHazePlayBlendSpaceData MayStruggle;
	UPROPERTY(Category = "Struggle")
    FHazePlayBlendSpaceData BothStruggle;
};