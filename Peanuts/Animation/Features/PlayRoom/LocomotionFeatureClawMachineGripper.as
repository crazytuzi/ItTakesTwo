class ULocomotionFeatureClawMachineGripper : UHazeLocomotionFeatureBase
{
	default Tag = n"ClawMachine";
    
	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData Idle;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StartFwd;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData MoveFwd;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StopFwd;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StartLeft;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData MoveLeft;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StopLeft;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StartRight;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData MoveRight;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StopRight;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StartBack;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData MoveBack;

	UPROPERTY(Category = "ClawMachine")
    FHazePlaySequenceData StopBack;

	UPROPERTY(Category = "Grab")
    FHazePlaySequenceData GrabStart;

	UPROPERTY(Category = "Grab")
    FHazePlaySequenceData GrabMiss;

	UPROPERTY(Category = "Grab")
    FHazePlaySequenceData MissMH;

	UPROPERTY(Category = "Grab")
    FHazePlaySequenceData Reset;
    
	UPROPERTY(Category = "Grab")
    FHazePlayBlendSpaceData MoveBS;

	UPROPERTY(Category = "Grab")
    FHazePlayBlendSpaceData StopBS;

};