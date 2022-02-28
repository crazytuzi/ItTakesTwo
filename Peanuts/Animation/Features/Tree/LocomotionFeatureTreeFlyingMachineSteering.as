class ULocomotionFeatureTreeFlyingMachineSteering : UHazeLocomotionFeatureBase
{

    default Tag = n"FlyingMachine";


	UPROPERTY(Category= "FlyingMachineSteering")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category= "FlyingMachineSteering")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Category= "FlyingMachineSteering")
	FHazePlaySequenceData BoostFight;

}