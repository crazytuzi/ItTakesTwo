class ULocomotionFeatureGrindTransfer : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureGrindTransfer()
    {
        Tag = n"GrindTransfer";
    }
	
    UPROPERTY(Category = "GrindTransfer Left")
    FHazePlaySequenceData JumpLeft;

	UPROPERTY(Category = "GrindTransfer Left")
    FHazePlaySequenceData LandLeft;

	UPROPERTY(Category = "GrindTransfer Right")
    FHazePlaySequenceData JumpRight;

	UPROPERTY(Category = "GrindTransfer Right")
    FHazePlaySequenceData LandRight;

	
}