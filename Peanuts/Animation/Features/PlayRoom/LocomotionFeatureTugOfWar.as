class ULocomotionFeatureTugOfWar : UHazeLocomotionFeatureBase
{

	default Tag = n"TugOfWar";

	UPROPERTY(Category = "Weapon")
	FHazePlaySequenceData Unequip;

	UPROPERTY(Category = "Weapon")
	FHazePlaySequenceData Equip;

	UPROPERTY(Category = "TugOfWar")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TugOfWar")
	FHazePlaySequenceData SpinRopeAlone;
	
	UPROPERTY(Category = "TugOfWar")
	FHazePlayBlendSpaceData StruggleMh;

	UPROPERTY(Category = "TugOfWar")
	FHazePlaySequenceData StepFwd;

	UPROPERTY(Category = "TugOfWar")
	FHazePlaySequenceData StepBck;

	UPROPERTY(Category = "GameOver")
	FHazePlaySequenceData GameWon;

	UPROPERTY(Category = "GameOver")
	FHazePlaySequenceData FallDown;



}