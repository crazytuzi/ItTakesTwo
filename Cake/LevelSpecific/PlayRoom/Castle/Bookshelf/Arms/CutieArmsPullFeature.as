class UCutieArmsPullFeature : UHazeLocomotionFeatureBase
{
    UCutieArmsPullFeature()
    {
        Tag = n"EdgeHang";
    }

   	UPROPERTY()
    FHazePlaySequenceData MH;

	UPROPERTY()
    FHazePlaySequenceData Enter;
	UPROPERTY()
    FHazePlaySequenceData Exit;

	UPROPERTY()
	FHazePlaySequenceData GrabMH;
	UPROPERTY()
	FHazePlaySequenceData StruggleMH;
};