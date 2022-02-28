
class ULocomotionFeatureHeroWaspAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	UPROPERTY(Category = "Animation")
    FHazePlayRndSequenceData IdleAnimations;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceByValueData MovementAnimations;
};