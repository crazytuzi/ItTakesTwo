class ULocomotionFeatureHomeworkPen: UHazeLocomotionFeatureBase
{
   default Tag = n"HomeworkPen";

    UPROPERTY()
    FHazePlaySequenceData Enter;

	UPROPERTY()
    FHazePlayBlendSpaceData DrawBS;

	UPROPERTY()
    FHazePlaySequenceData JumpOff;

	UPROPERTY()
    FHazePlaySequenceData Additive;

	UPROPERTY()
    FHazePlaySequenceData IKPose;
};