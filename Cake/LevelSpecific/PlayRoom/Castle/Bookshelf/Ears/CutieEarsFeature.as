class UCutieEarsFeature : UHazeLocomotionFeatureBase
{
    UCutieEarsFeature()
    {
        Tag = n"TowerHang";
    }

    UPROPERTY(Category = "TowerHangCutie")
    FHazePlayBlendSpaceData TowerHangBS;

	UPROPERTY(Category = "BodyAnimations")
    FHazePlayBlendSpaceData Enter;
	
	UPROPERTY(Category = "BodyAnimations")
    FHazePlayBlendSpaceData Exit;
	/*UPROPERTY(Category = "BodyAnimations")
    FHazePlaySequenceData EnterRight;
	UPROPERTY(Category = "BodyAnimations")
    FHazePlaySequenceData ExitRight;*/

	UPROPERTY(Category = "BodyAnimations")
	FHazePlayBlendSpaceData TowerHangGrabBS;
	
	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData LeftEarEnter;
	
	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData LeftEarExit;
	
	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData RightEarEnter;
	
	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData RightEarExit;

	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData FreeEarEnter;

	UPROPERTY(Category = "EarOverrides")
	FHazePlaySequenceData FreeEarExit;

	UPROPERTY(Category = "EarOverrides")
	FHazePlayBlendSpaceData LeftEarOverrideBS;
	
	UPROPERTY(Category = "EarOverrides")
	FHazePlayBlendSpaceData RightEarOverrideBS;

};