class UCutieLegPullFeature : UHazeLocomotionFeatureBase
{
    UCutieLegPullFeature()
    {
        Tag = n"LegPull";
    }

    UPROPERTY(Category = "LegPullCutie")
    FHazePlayBlendSpaceData PullLegBS;

	UPROPERTY(Category = "LegPullCutieGrabbed")
    FHazePlayBlendSpaceData Enter;
	UPROPERTY(Category = "LegPullCutieGrabbed")
    FHazePlayBlendSpaceData Exit;

	UPROPERTY(Category = "TowerHangCutieGrabbed")
	FHazePlayBlendSpaceData PullLegGrabBS;
};