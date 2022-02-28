
class ULocomotionFeatureDoublePullCutie : UHazeLocomotionFeatureBase
{
	default Tag = n"DoublePull";

	UPROPERTY(Category = "Safe Space")
    FHazePlaySequenceData StartMH;
	UPROPERTY(Category = "Safe Space")
    FHazePlaySequenceData StartEnter;
	UPROPERTY(Category = "Safe Space")
    FHazePlaySequenceData StartExit;

 	UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData Enter;
    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData DragMH;
    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData Struggle;
    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData CrawlBackwards;
    UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData DragForward;
	UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData DropDrag;
	UPROPERTY(Category = "Locomotion Double Pull")
    FHazePlaySequenceData Exit;

	UPROPERTY(Category = "LegOverride")
    FHazePlaySequenceData LegEnter;
	UPROPERTY(Category = "LegOverride")
    FHazePlaySequenceData LegMH;
	UPROPERTY(Category = "LegOverride")
    FHazePlaySequenceData LegExit;
};