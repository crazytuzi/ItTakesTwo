class ULocomotionFeatureTreeFlyingMachineTurret : UHazeLocomotionFeatureBase
{

    default Tag = n"FlyingMachine";

    UPROPERTY(Category = "FlyingMachineTurret")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category= "FlyingMachineTurret")
	FHazePlaySequenceData FireLeft;

	UPROPERTY(Category= "FlyingMachineTurret")
	FHazePlaySequenceData FireRight;

}