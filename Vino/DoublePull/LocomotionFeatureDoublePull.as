
class ULocomotionFeatureDoublePull : UHazeLocomotionFeatureBase
{
	default Tag = n"DoublePull";

    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData MH;

    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData Struggle;

    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData Walk;

	UPROPERTY()
	UAnimSequence CancelAnimation;
};