class UPlayerCutieEarsFeature : UHazeLocomotionFeatureBase
{
    UPlayerCutieEarsFeature()
    {
        Tag = n"TowerHang";
    }

	UPROPERTY(Category = "TowerHangCutieGrabbed")
    FHazePlaySequenceData MayEnter;
	UPROPERTY(Category = "TowerHangCutieGrabbed")
    FHazePlaySequenceData MayExit;
	UPROPERTY(Category = "TowerHangCutieGrabbed")
    FHazePlaySequenceData CodyEnter;
	UPROPERTY(Category = "TowerHangCutieGrabbed")
    FHazePlaySequenceData CodyExit;

	UPROPERTY()
	FHazePlayBlendSpaceData HangBS;
};